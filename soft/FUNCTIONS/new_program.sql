CREATE OR REPLACE FUNCTION New_Program(_Language text, _Program text)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID   integer;
_ReturnValue text;
BEGIN

INSERT INTO Programs (Program, PhaseID)
SELECT
    _Program,
    Phases.PhaseID
FROM Languages
INNER JOIN Phases ON Phases.LanguageID = Languages.LanguageID
WHERE Languages.Language = _Language
ORDER BY Phases.PhaseID
LIMIT 1
RETURNING ProgramID INTO STRICT _ProgramID;

RETURN _ProgramID;
END;
$$;
