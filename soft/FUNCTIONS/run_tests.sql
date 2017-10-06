CREATE OR REPLACE FUNCTION Run_Tests(_Language text)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_TestID         integer;
_Program        text;
_ProgramID      integer;
_ExpectedType   regtype;
_ExpectedValue  text;
_ExpectedTypes  regtype[];
_ExpectedValues text[];
_ExpectedError  text;
_ExpectedLog    text;
_ProgramNodeID  integer;
_TestResult     boolean;
_ResultNodeID   integer;
_ResultType     regtype;
_ResultValue    text;
_ResultTypes    regtype[];
_ResultValues   text[];
_OK             boolean;
_Error          text;
BEGIN

_TestResult := TRUE;

FOR
    _TestID,
    _Program,
    _ProgramID,
    _ExpectedType,
    _ExpectedValue,
    _ExpectedTypes,
    _ExpectedValues,
    _ExpectedError,
    _ExpectedLog
IN
SELECT
    Tests.TestID,
    Programs.Program,
    Tests.ProgramID,
    Tests.ExpectedType,
    Tests.ExpectedValue,
    Tests.ExpectedTypes,
    Tests.ExpectedValues,
    Tests.ExpectedError,
    Tests.ExpectedLog
FROM Tests
INNER JOIN Programs  ON Programs.ProgramID   = Tests.ProgramID
INNER JOIN Phases    ON Phases.PhaseID       = Programs.PhaseID
INNER JOIN Languages ON Languages.LanguageID = Phases.LanguageID
WHERE Languages.Language = _Language
ORDER BY Tests.TestID
LOOP

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
        _NodeID   := _ProgramNodeID,
        _Severity := 'DEBUG1',
        _Message  := format('Result %L %L, Expected %L %L, Error %L',
            COALESCE(_ResultType::text,'['||array_to_string(_ResultTypes,',')||']'),
            COALESCE(_ResultValue,'['||array_to_string(_ResultValues,',')||']'),
            COALESCE(_ExpectedType::text,'['||array_to_string(_ExpectedTypes,',')||']'),
            COALESCE(_ExpectedValue,'['||array_to_string(_ExpectedValues,',')||']'),
            _Error
        )
    );

    IF     _OK AND _ExpectedType  = _ResultType  AND _ExpectedValue  = _ResultValue
    OR     _OK AND _ExpectedTypes = _ResultTypes AND _ExpectedValues = _ResultValues
    OR NOT _OK AND _ExpectedError = _Error
    OR     _OK AND EXISTS (
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
    ) THEN
        PERFORM Log(
            _NodeID   := _ProgramNodeID,
            _Severity := 'NOTICE',
            _Message  := format('Test %L %s for language %L',
                Colorize(_Program),
                Colorize('OK', 'GREEN'),
                Colorize(_Language)
            )
        );
    ELSE
        _TestResult := FALSE;
        PERFORM Log(
            _NodeID   := _ProgramNodeID,
            _Severity := 'NOTICE',
            _Message  := format('Test %L %s for language %L',
                Colorize(_Program),
                Colorize('FAILED', 'RED'),
                Colorize(_Language)
            )
        );
    END IF;

END LOOP;

RETURN _TestResult;
END;
$$;
