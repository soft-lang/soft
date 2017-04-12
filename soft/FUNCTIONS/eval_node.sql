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
_ReturnValue      text;
_CastTest         text;
BEGIN

SELECT
    Phases.Phase,
    pg_proc.proname,
    pg_proc.proargtypes,
    pg_proc.prorettype::regtype
INTO
    _Phase,
    _FunctionName,
    _ArgTypes,
    _ReturnType
FROM Nodes
INNER JOIN NodeTypes    ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
INNER JOIN pg_proc      ON pg_proc.proname      = NodeTypes.NodeType
INNER JOIN pg_namespace ON pg_namespace.oid     = pg_proc.pronamespace
INNER JOIN Programs     ON Programs.ProgramID   = Nodes.ProgramID
INNER JOIN Phases       ON Phases.PhaseID       = Programs.PhaseID
WHERE pg_namespace.nspname = Phases.Phase
AND   Nodes.NodeID         = _NodeID;
IF NOT FOUND THEN
    RETURN FALSE;
END IF;

SELECT array_agg(pg_type.typname::regtype ORDER BY TypeOIDs.Ordinality)
INTO STRICT _InputArgTypes
FROM (
    SELECT * FROM unnest(_ArgTypes) WITH ORDINALITY AS TypeOID
) AS TypeOIDs
INNER JOIN pg_type ON pg_type.oid = TypeOIDs.TypeOID;

RAISE DEBUG 'FunctionName % ArgTypes % ReturnType % InputArgTypes %', _FunctionName, _ArgTypes, _ReturnType, _InputArgTypes;

SELECT
    format('SELECT %I.%I(%s)::text',
        _Phase,
        _FunctionName,
        string_agg(
            quote_literal(Nodes.TerminalValue)||'::'||Nodes.TerminalType::text,
            ','
        ORDER BY Edges.EdgeID)
    ),
    array_agg(Nodes.TerminalType ORDER BY Edges.EdgeID)
INTO STRICT
    _SQL,
    _ParentValueTypes
FROM Edges
INNER JOIN Nodes ON Nodes.NodeID = Edges.ParentNodeID
WHERE Edges.ChildNodeID = _NodeID
AND Edges.DeathPhaseID IS NULL
AND Nodes.DeathPhaseID IS NULL;

RAISE DEBUG 'SQL % ParentValueTypes %', _SQL, _ParentValueTypes;

IF _ReturnType = 'anyelement'::regtype THEN
    _ReturnType := Determine_Return_Type(_InputArgTypes, _ParentValueTypes);
END IF;

EXECUTE _SQL INTO STRICT _ReturnValue;

RAISE DEBUG 'ReturnType % ReturnValue %', _ReturnType, _ReturnValue;

EXECUTE format('SELECT %L::%s::text', _ReturnValue, _ReturnType) INTO STRICT _CastTest;
IF _ReturnValue IS DISTINCT FROM _CastTest THEN
    RAISE EXCEPTION 'ReturnValue "%" resulted in the different value "%" when casted to type "%" and then back to text', _ReturnValue, _CastTest, _ReturnType;
END IF;

PERFORM Set_Node_Value(_NodeID := _NodeID, _TerminalType := _ReturnType, _TerminalValue := _ReturnValue);

PERFORM Log(
    _NodeID   := _NodeID,
    _Severity := 'DEBUG3',
    _Message  := format('Computed node "%s" to value "%s" of type "%s"', Colorize(Node(_NodeID)), Colorize(_ReturnValue,'CYAN'), Colorize(_ReturnType::text,'MAGENTA'))
);

RETURN TRUE;
END;
$$;
