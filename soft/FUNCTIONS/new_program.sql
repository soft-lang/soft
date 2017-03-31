CREATE OR REPLACE FUNCTION New_Program(_Language text, _Program text)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_LanguageID    integer;
_ProgramID     integer;
_PhaseID       integer;
_Nodes         text;
_OK            boolean;
_ProgramNodeID integer;
BEGIN

SELECT
    Languages.LanguageID,
    Phases.PhaseID
INTO STRICT
    _LanguageID,
    _PhaseID
FROM Languages
INNER JOIN Phases ON Phases.LanguageID = Languages.LanguageID
WHERE Languages.Language = _Language
ORDER BY Phases.PhaseID
LIMIT 1;

INSERT INTO Programs ( LanguageID,  Program,  PhaseID)
VALUES               (_LanguageID, _Program, _PhaseID)
RETURNING ProgramID INTO STRICT _ProgramID;

RETURN _ProgramID;
END;
$$;
