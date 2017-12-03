CREATE OR REPLACE FUNCTION Eval_Node(_NodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_Phase                  text;
_FunctionName           name;
_ArgTypes               oidvector;
_ReturnType             regtype;
_InputArgTypes          regtype[];
_SQL                    text;
_ParentValueTypes       regtype[];
_ParentArgValues        text;
_ReturnValue            text;
_CastTest               text;
_Count                  integer;
_ZeroArgsFunctionExists boolean;
_OK                     boolean;
BEGIN

SELECT
    Phases.Phase,
    pg_proc.proname AS FunctionName,
    (pg_proc.pronargs = 0) AS ZeroArgsFunctionExists
INTO
    _Phase,
    _FunctionName,
    _ZeroArgsFunctionExists
FROM Nodes
INNER JOIN NodeTypes    ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
INNER JOIN pg_proc      ON pg_proc.proname      = NodeTypes.NodeType
INNER JOIN pg_namespace ON pg_namespace.oid     = pg_proc.pronamespace
INNER JOIN Programs     ON Programs.ProgramID   = Nodes.ProgramID
INNER JOIN Phases       ON Phases.PhaseID       = Programs.PhaseID
WHERE pg_namespace.nspname = Phases.Phase
AND   Nodes.NodeID         = _NodeID
ORDER BY pg_proc.pronargs
LIMIT 1;
IF NOT FOUND THEN
    RETURN NULL;
END IF;

SELECT
    array_agg(Primitive_Type(Nodes.NodeID) ORDER BY Edges.EdgeID),
    string_agg(
        quote_literal(Primitive_Value(Nodes.NodeID))
        ||'::'||
        Primitive_Type(Nodes.NodeID)::text,
        ','
        ORDER BY Edges.EdgeID
    )
INTO STRICT
    _ParentValueTypes,
    _ParentArgValues
FROM Edges
INNER JOIN Nodes ON Nodes.NodeID = Edges.ParentNodeID
WHERE Edges.ChildNodeID = _NodeID
AND Edges.DeathPhaseID IS NULL
AND Nodes.DeathPhaseID IS NULL;

IF EXISTS (
    SELECT 1
    FROM Edges
    INNER JOIN Nodes ON Nodes.NodeID = Dereference(Edges.ParentNodeID)
    WHERE Edges.ChildNodeID = _NodeID
    AND Edges.DeathPhaseID  IS NULL
    AND Nodes.DeathPhaseID  IS NULL
    AND Nodes.PrimitiveType IS NULL
)
AND _ZeroArgsFunctionExists IS NOT TRUE
THEN
    -- There are at least one parent node with no value/type yet,
    -- or the parent is some valueless node such as a function,
    -- in which case we can only compute a value for it if
    -- this node we want to eval has a EVAL-function with empty arguments,
    -- and since we don't have that we can't eval.
    RETURN NULL;
END IF;

WITH X AS (
    SELECT
        (
            SELECT array_agg(pg_type.typname::regtype ORDER BY TypeOIDs.Ordinality)
            FROM (
                SELECT * FROM unnest(pg_proc.proargtypes) WITH ORDINALITY AS TypeOID
            ) AS TypeOIDs
            INNER JOIN pg_type ON pg_type.oid = TypeOIDs.TypeOID
        ) AS InputArgTypes,
        pg_proc.prorettype::regtype AS ReturnType
    FROM pg_proc
    INNER JOIN pg_namespace ON pg_namespace.oid = pg_proc.pronamespace
    WHERE pg_namespace.nspname = _Phase
    AND   pg_proc.proname      = _FunctionName
)
SELECT
    X.InputArgTypes,
    X.ReturnType,
    COUNT(*) OVER ()
INTO
    _InputArgTypes,
    _ReturnType,
    _Count
FROM X
WHERE Matching_Input_Types(X.InputArgTypes, _ParentValueTypes)
AND NOT EXISTS (SELECT 1 FROM X AS X2 WHERE X2.InputArgTypes = _ParentValueTypes)
OR X.InputArgTypes = _ParentValueTypes;
IF FOUND THEN
    IF _Count IS DISTINCT FROM 1 THEN
        RAISE EXCEPTION 'Multiple matches for: %.%(%), Count %', _Phase, _FunctionName, _ParentValueTypes, _Count;
    END IF;

    _SQL := format('SELECT %I.%I(%s)::text', _Phase, _FunctionName, _ParentArgValues);

    RAISE NOTICE 'SQL: %', _SQL;

    IF _ReturnType = 'anyelement'::regtype THEN
        _ReturnType := Determine_Return_Type(_InputArgTypes, _ParentValueTypes);
    END IF;

    EXECUTE _SQL INTO STRICT _ReturnValue;

    IF _ReturnType = 'numeric'::regtype
    AND (Language(_NodeID)).StripZeroes THEN
        _ReturnValue := Strip_Zeroes(_ReturnValue::numeric)::text;
    END IF;

    EXECUTE format('SELECT %L::%s::text', _ReturnValue, _ReturnType) INTO STRICT _CastTest;
    IF _ReturnValue IS DISTINCT FROM _CastTest THEN
        RAISE EXCEPTION 'ReturnValue "%" resulted in the different value "%" when casted to type "%" and then back to text', _ReturnValue, _CastTest, _ReturnType;
    END IF;

ELSE
    RAISE EXCEPTION 'Type mismatch: %.%(%)', _Phase, _FunctionName, _ParentValueTypes;
END IF;

PERFORM Set_Node_Value(_NodeID := _NodeID, _PrimitiveType := _ReturnType, _PrimitiveValue := _ReturnValue);

IF (Language(_NodeID)).NegativeZeroes
AND Node_Type(_NodeID) = 'UNARY_MINUS'
AND _ReturnValue      = '0'
AND _ParentArgValues NOT LIKE '''-%'
THEN
    UPDATE Nodes
    SET PrimitiveValue = '-' || PrimitiveValue
    WHERE NodeID = _NodeID
    RETURNING TRUE INTO STRICT _OK;
END IF;

PERFORM Log(
    _NodeID   := _NodeID,
    _Severity := 'DEBUG3',
    _Message  := format('Computed node "%s" to value "%s" of type "%s"', Colorize(Node(_NodeID)), Colorize(_ReturnValue,'CYAN'), Colorize(_ReturnType::text,'MAGENTA'))
);

RETURN TRUE;
END;
$$;
