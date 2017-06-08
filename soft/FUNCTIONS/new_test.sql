CREATE OR REPLACE FUNCTION New_Test(
_Language       text,
_Program        text,
_SourceCode     text,
_ExpectedType   regtype   DEFAULT NULL,
_ExpectedValue  text      DEFAULT NULL,
_ExpectedTypes  regtype[] DEFAULT NULL,
_ExpectedValues text[]    DEFAULT NULL,
_ExpectedError  text      DEFAULT NULL,
_ExpectedLog    text      DEFAULT NULL
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID     integer;
_ProgramNodeID integer;
_TestID        integer;
_NodeID        integer;
_ResultNodeID  integer;
_ResultType    regtype;
_ResultValue   text;
_ResultTypes   regtype[];
_ResultValues  text[];
_OK            boolean;
_Error         text;
BEGIN

_ProgramID := New_Program(_Language, _Program);

INSERT INTO Tests ( ProgramID,  ExpectedType,  ExpectedValue,  ExpectedTypes,  ExpectedValues,  ExpectedError,  ExpectedLog)
VALUES            (_ProgramID, _ExpectedType, _ExpectedValue, _ExpectedTypes, _ExpectedValues, _ExpectedError, _ExpectedLog)
RETURNING    TestID
INTO STRICT _TestID;

_NodeID := New_Node(
    _Program       := _Program,
    _NodeType      := 'SOURCE_CODE',
    _PrimitiveType  := 'text'::regtype,
    _PrimitiveValue := _SourceCode
);

PERFORM Log(
    _NodeID   := _NodeID,
    _Severity := 'NOTICE',
    _Message  := format('New test %L for language %L', Colorize(_Program,'CYAN'), Colorize(_Language,'MAGENTA'))
);

_ProgramNodeID := Get_Program_Node(_ProgramID);

UPDATE Programs SET Direction = 'ENTER' WHERE ProgramID = _ProgramID RETURNING TRUE INTO STRICT _OK;

PERFORM Enter_Node(_ProgramNodeID);

SELECT       OK,  Error
INTO STRICT _OK, _Error
FROM Run(_ProgramID := _ProgramID);

_ResultNodeID := Dereference((SELECT NodeID FROM Programs WHERE ProgramID = _ProgramID));

SELECT     PrimitiveType, PrimitiveValue
INTO STRICT  _ResultType,   _ResultValue
FROM Nodes
WHERE NodeID = _ResultNodeID;

IF _ResultType IS NULL THEN
    SELECT
        array_agg(Primitive_Type(Nodes.NodeID)  ORDER BY Edges.EdgeID),
        array_agg(Primitive_Value(Nodes.NodeID) ORDER BY Edges.EdgeID)
    INTO STRICT
        _ResultTypes,
        _ResultValues
    FROM Edges
    INNER JOIN Nodes ON Nodes.NodeID = Edges.ParentNodeID
    WHERE Edges.ChildNodeID = _ResultNodeID
    AND Edges.DeathPhaseID IS NULL
    AND Nodes.DeathPhaseID IS NULL;
END IF;

PERFORM Log(
    _NodeID   := _NodeID,
    _Severity := 'NOTICE',
    _Message  := format('Result %L %L, Error %L', _ResultType, _ResultValue, _Error)
);

PERFORM Log(
    _NodeID   := _NodeID,
    _Severity := 'NOTICE',
    _Message  := format('Test %L %s for language %L',
        Colorize(_Program),
        CASE WHEN _OK AND _ExpectedType   = _ResultType  AND _ExpectedValue  = _ResultValue
        OR        _OK AND _ExpectedTypes  = _ResultTypes AND _ExpectedValues = _ResultValues
        OR    NOT _OK AND _ExpectedError = _Error
        OR        _OK AND EXISTS (
            SELECT 1
            FROM Log
            INNER JOIN Phases    ON Phases.PhaseID       = Log.PhaseID
            INNER JOIN Nodes     ON Nodes.NodeID         = Log.NodeID
            INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
            WHERE Log.ProgramID = _ProgramID
            AND format('%s %s %s',
                Phases.Phase,
                Log.Severity::text,
                NodeTypes.NodeType
            ) = _ExpectedLog
        )
        THEN Colorize('OK', 'GREEN')
        ELSE Colorize('FAILED', 'RED')
        END,
        Colorize(_Language)
    )
);

RETURN _TestID;
END;
$$;
