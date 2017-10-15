CREATE OR REPLACE FUNCTION Run_Test(
_Language    text,
_Program     text,
_LogSeverity severity DEFAULT NULL
)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_DefaultLogSeverity severity;
_TestID             integer;
_ProgramID          integer;
_ExpectedType       regtype;
_ExpectedValue      text;
_ExpectedTypes      regtype[];
_ExpectedValues     text[];
_ExpectedError      text;
_ExpectedLog        text;
_ExpectedSTDOUT     text[];
_ProgramNodeID      integer;
_ResultNodeID       integer;
_ResultType         regtype;
_ResultValue        text;
_ResultTypes        regtype[];
_ResultValues       text[];
_OK                 boolean;
_TestResult         boolean;
_Error              text;
BEGIN

SELECT
    Tests.TestID,
    Tests.ProgramID,
    Tests.ExpectedType,
    Tests.ExpectedValue,
    Tests.ExpectedTypes,
    Tests.ExpectedValues,
    Tests.ExpectedError,
    Tests.ExpectedLog,
    Tests.ExpectedSTDOUT,
    Programs.LogSeverity
INTO
    _TestID,
    _ProgramID,
    _ExpectedType,
    _ExpectedValue,
    _ExpectedTypes,
    _ExpectedValues,
    _ExpectedError,
    _ExpectedLog,
    _ExpectedSTDOUT,
    _DefaultLogSeverity
FROM Tests
INNER JOIN Programs  ON Programs.ProgramID   = Tests.ProgramID
INNER JOIN Languages ON Languages.LanguageID = Programs.LanguageID
WHERE Languages.Language = _Language
AND   Programs.Program   = _Program;
IF NOT FOUND THEN
    RAISE EXCEPTION 'No program named "%" for language "%"', _Program, _Language;
END IF;

_LogSeverity := COALESCE(_LogSeverity, _DefaultLogSeverity);

UPDATE Programs
SET LogSeverity = _LogSeverity
WHERE ProgramID = _ProgramID
RETURNING TRUE INTO STRICT _OK;

UPDATE Tests
SET StartedAt = clock_timestamp()
WHERE TestID = _TestID
RETURNING TRUE INTO STRICT _OK;

_ProgramNodeID := Get_Program_Node(_ProgramID);

SELECT       OK,  Error
INTO STRICT _OK, _Error
FROM Run(_Language, _Program);

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
        COALESCE(_ResultType::text,   format('[%s]', array_to_string(_ResultTypes,','))),
        COALESCE(_ResultValue,        format('[%s]', array_to_string(_ResultValues,','))),
        COALESCE(_ExpectedType::text, format('[%s]', array_to_string(_ExpectedTypes,','))),
        COALESCE(_ExpectedValue,      format('[%s]', array_to_string(_ExpectedValues,','))),
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
)
OR _ExpectedSTDOUT = COALESCE((
    SELECT array_agg(Log.Message ORDER BY Log.LogID)
    FROM Log
    WHERE Log.ProgramID = _ProgramID
    AND   Log.Severity  = 'STDOUT'
),ARRAY[NULL]::text[]) THEN
    PERFORM Log(
        _NodeID   := _ProgramNodeID,
        _Severity := 'NOTICE',
        _Message  := format('Test %L %s for language %L',
            Colorize(_Program),
            Colorize('OK', 'GREEN'),
            Colorize(_Language)
        )
    );
    _TestResult := TRUE;
ELSE
    PERFORM Log(
        _NodeID   := _ProgramNodeID,
        _Severity := 'NOTICE',
        _Message  := format('Test %L %s for language %L',
            Colorize(_Program),
            Colorize('FAILED', 'RED'),
            Colorize(_Language)
        )
    );
    _TestResult := FALSE;
END IF;

UPDATE Programs
SET LogSeverity = _DefaultLogSeverity
WHERE ProgramID = _ProgramID
RETURNING TRUE INTO STRICT _OK;

UPDATE Tests
SET FinishedAt = clock_timestamp()
WHERE TestID = _TestID
RETURNING TRUE INTO STRICT _OK;

RETURN _TestResult;
END;
$$;

CREATE OR REPLACE FUNCTION Run_Test(_ProcessID integer)
RETURNS batchjobstate
LANGUAGE plpgsql
AS $$
DECLARE
_Language text;
_Program  text;
BEGIN
SELECT
    Languages.Language,
    Programs.Program
INTO
    _Language,
    _Program
FROM Tests
INNER JOIN Programs  ON Programs.ProgramID   = Tests.ProgramID
INNER JOIN Languages ON Languages.LanguageID = Programs.LanguageID
WHERE Tests.StartedAt IS NULL
ORDER BY Tests.TestID;
IF NOT FOUND THEN
    RETURN 'DONE';
END IF;

PERFORM Run_Test(_Language, _Program);

RETURN 'AGAIN';
END;
$$;
