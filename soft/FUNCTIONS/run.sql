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

_ProgramNodeID := Get_Program_Node(_ProgramID);

UPDATE Programs
SET Direction = 'ENTER'
WHERE ProgramID = _ProgramID
RETURNING TRUE INTO STRICT _OK;

PERFORM Enter_Node(_ProgramNodeID);

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

RAISE NOTICE '%', _RunUntilPhaseID;

UPDATE Programs SET
    RunAt           = now(),
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
_ProgramID integer;
BEGIN

SELECT ProgramID
INTO  _ProgramID
FROM Programs
WHERE DeathTime IS NULL
AND   RunAt           <  clock_timestamp()
AND  (RunUntilPhaseID >= PhaseID)       IS NOT TRUE
AND  (Iterations      >  MaxIterations) IS NOT TRUE
ORDER BY RunAt
LIMIT 1;
IF NOT FOUND THEN
    RETURN 'DONE';
END IF;

PERFORM Walk_Tree(_ProgramID);

RETURN 'AGAIN';
END;
$$;

GRANT ALL ON FUNCTION Run(_ProcessID integer) TO pgcronjob;

SELECT cron.Register('soft.Run(integer)',
    _IntervalAGAIN  := '0'::interval,
    _IntervalDONE   := '1 second'::interval
);
