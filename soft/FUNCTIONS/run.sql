CREATE OR REPLACE FUNCTION Run(
OUT OK         boolean,
OUT Error      text,
_Language      text,
_Program       text,
_RunUntilPhase name DEFAULT NULL
)
RETURNS record
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID     integer;
_ProgramNodeID integer;
_OK            boolean;
BEGIN
OK := TRUE;

SELECT Programs.ProgramID
INTO STRICT    _ProgramID
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

LOOP
    IF _RunUntilPhase IS NOT NULL
    AND EXISTS (
        SELECT 1
        FROM Programs
        INNER JOIN Phases ON Phases.PhaseID = Programs.PhaseID
        WHERE Programs.ProgramID = _ProgramID
        AND   Phases.Phase       = _RunUntilPhase
    ) THEN
        EXIT;
    END IF;
    BEGIN
        IF NOT Walk_Tree(_ProgramID) THEN
            EXIT;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        OK    := FALSE;
        Error := SQLERRM;
        RETURN;
    END;
END LOOP;
RETURN;
END;
$$;
