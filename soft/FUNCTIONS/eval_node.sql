CREATE OR REPLACE FUNCTION Eval_Node(_NodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_Phase            text;
_FunctionName     name;
_ArgTypes         oidvector;
_ReturnType       regtype;
_InputArgTypes    regtype[];
_SQL              text;
_ParentValueTypes regtype[];
_ParentArgValues  text;
_ReturnValue      text;
_CastTest         text;
_Count            integer;
BEGIN

SELECT
    Phases.Phase,
    pg_proc.proname AS FunctionName
INTO
    _Phase,
    _FunctionName
FROM Nodes
INNER JOIN NodeTypes    ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
INNER JOIN pg_proc      ON pg_proc.proname      = NodeTypes.NodeType
INNER JOIN pg_namespace ON pg_namespace.oid     = pg_proc.pronamespace
INNER JOIN Programs     ON Programs.ProgramID   = Nodes.ProgramID
INNER JOIN Phases       ON Phases.PhaseID       = Programs.PhaseID
WHERE pg_namespace.nspname = Phases.Phase
AND   Nodes.NodeID         = _NodeID;
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

SELECT
    X.InputArgTypes,
    X.ReturnType,
    COUNT(*) OVER ()
INTO
    _InputArgTypes,
    _ReturnType,
    _Count
FROM (
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
) AS X
WHERE Matching_Input_Types(X.InputArgTypes, _ParentValueTypes);
IF NOT FOUND THEN
    RAISE EXCEPTION 'Type mismatch: %.%(%)', _Phase, _FunctionName, _ParentValueTypes;
END IF;

IF _Count IS DISTINCT FROM 1 THEN
    RAISE EXCEPTION 'Multiple matches for: %.%(%)', _Phase, _FunctionName, _ParentValueTypes;
END IF;

_SQL := format('SELECT %I.%I(%s)::text', _Phase, _FunctionName, _ParentArgValues);

IF _ReturnType = 'anyelement'::regtype THEN
    _ReturnType := Determine_Return_Type(_InputArgTypes, _ParentValueTypes);
END IF;

EXECUTE _SQL INTO STRICT _ReturnValue;

EXECUTE format('SELECT %L::%s::text', _ReturnValue, _ReturnType) INTO STRICT _CastTest;
IF _ReturnValue IS DISTINCT FROM _CastTest THEN
    RAISE EXCEPTION 'ReturnValue "%" resulted in the different value "%" when casted to type "%" and then back to text', _ReturnValue, _CastTest, _ReturnType;
END IF;

PERFORM Set_Node_Value(_NodeID := _NodeID, _PrimitiveType := _ReturnType, _PrimitiveValue := _ReturnValue);

PERFORM Log(
    _NodeID   := _NodeID,
    _Severity := 'DEBUG3',
    _Message  := format('Computed node "%s" to value "%s" of type "%s"', Colorize(Node(_NodeID)), Colorize(_ReturnValue,'CYAN'), Colorize(_ReturnType::text,'MAGENTA'))
);

RETURN TRUE;
END;
$$;
