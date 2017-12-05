CREATE OR REPLACE FUNCTION Run(
_Language      text,
_Program       text,
_RunUntilPhase name    DEFAULT NULL,
_MaxIterations integer DEFAULT NULL
)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID       integer;
_LanguageID      integer;
_ProcessID       integer;
_ProgramNodeID   integer;
_RunUntilPhaseID integer;
_Iterations      integer;
_OK              boolean;
BEGIN

SELECT Programs.ProgramID, Languages.LanguageID
INTO STRICT    _ProgramID,          _LanguageID
FROM Programs
INNER JOIN Languages ON Languages.LanguageID = Programs.LanguageID
WHERE Languages.Language = _Language
AND   Programs.Program   = _Program;

PERFORM Set_Program_Node(Get_Program_Node(_ProgramID));

IF _RunUntilPhase IS NOT NULL THEN
    SELECT        PhaseID
    INTO _RunUntilPhaseID
    FROM Phases
    WHERE LanguageID = _LanguageID
    AND   Phase      = _RunUntilPhase;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'No such phase "%" for language "%"', _RunUntilPhase, _Language;
    END IF;
END IF;

_ProcessID := cron.Register('soft.Run(integer)',
    _IntervalAGAIN  := '0'::interval,
    _ConnectionPool := 'soft.Run',
    _LogTableAccess := FALSE
);

UPDATE Programs SET
    ProcessID       = _ProcessID,
    RunUntilPhaseID = _RunUntilPhaseID,
    MaxIterations   = _MaxIterations
WHERE ProgramID = _ProgramID
RETURNING TRUE INTO STRICT _OK;

RETURN TRUE;
END;
$$;

CREATE OR REPLACE FUNCTION Run(_ProcessID integer)
RETURNS batchjobstate
SECURITY DEFINER
SET search_path TO soft, pg_temp
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID       integer;
_Program         text;
_NodeID          integer;
_ResultNodeID    integer;
_ResultType      regtype;
_ResultValue     text;
_ResultTypes     regtype[];
_ResultValues    text[];
_Error           text;
_RunAgain        boolean;
_ApplicationName text;
_Started         boolean;
_OK              boolean;
BEGIN

SELECT ProgramID,  Program,  NodeID,  Started
INTO  _ProgramID, _Program, _NodeID, _Started
FROM Programs
WHERE ProcessID = _ProcessID
AND   DeathTime IS NULL
AND  (PhaseID         >  RunUntilPhaseID) IS NOT TRUE
AND  (Iterations      >  MaxIterations)   IS NOT TRUE;
IF NOT FOUND THEN
    RETURN 'DONE';
END IF;

_ApplicationName := current_setting('application_name');
IF _ApplicationName NOT LIKE ('%'||_Program||'%') THEN
    PERFORM set_config('application_name', substr(format('%s %s', _ApplicationName, _Program),1,63), TRUE);
END IF;

IF NOT _Started THEN
    PERFORM Enter_Node(_NodeID);
    UPDATE Programs
    SET Started = TRUE
    WHERE ProgramID = _ProgramID
    RETURNING TRUE INTO STRICT _OK;
END IF;

_RunAgain := FALSE;
BEGIN
    _RunAgain := Walk_Tree(_ProgramID);
EXCEPTION WHEN OTHERS THEN
    _Error := SQLERRM;
    RAISE WARNING 'Walk_Tree(_ProgramID := %) died with error: %', _ProgramID, Colorize(_Error, 'RED');
END;

IF NOT _RunAgain THEN
    IF _Error IS NULL THEN
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
    END IF;

    UPDATE Programs SET
        DeathTime    = clock_timestamp(),
        ResultType   = _ResultType,
        ResultValue  = _ResultValue,
        ResultTypes  = _ResultTypes,
        ResultValues = _ResultValues,
        Error        = _Error
    WHERE ProgramID = _ProgramID
    RETURNING TRUE INTO STRICT _OK;
END IF;

RETURN 'AGAIN';
END;
$$;

GRANT ALL ON FUNCTION Run(_ProcessID integer) TO pgcronjob;

SELECT cron.New_Connection_Pool(_Name := 'soft.Run', _MaxProcesses := 8);
