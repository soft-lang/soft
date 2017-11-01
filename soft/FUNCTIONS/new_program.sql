CREATE OR REPLACE FUNCTION New_Program(
_Language    text,
_Program     text,
_LogSeverity severity DEFAULT 'NOTICE'
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID   integer;
_ReturnValue text;
_OK          boolean;
BEGIN

INSERT INTO Programs (Program, LanguageID, PhaseID, LogSeverity)
SELECT
    _Program,
    Languages.LanguageID,
    Phases.PhaseID,
    _LogSeverity
FROM Languages
INNER JOIN Phases ON Phases.LanguageID = Languages.LanguageID
WHERE Languages.Language = _Language
ORDER BY Phases.PhaseID
LIMIT 1
RETURNING ProgramID INTO STRICT _ProgramID;

INSERT INTO Environments ( ProgramID, EnvironmentID)
VALUES                   (_ProgramID, 0)
RETURNING TRUE INTO STRICT _OK;

RETURN _ProgramID;
END;
$$;
