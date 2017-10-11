CREATE OR REPLACE FUNCTION Set_Program_Phase(_Program text, _Language text, _Phase text)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID integer;
_PhaseID   integer;
_OK        boolean;
BEGIN
SELECT Programs.ProgramID, Phases.PhaseID
INTO STRICT    _ProgramID,       _PhaseID
FROM Programs
INNER JOIN Languages ON Languages.LanguageID = Programs.LanguageID
INNER JOIN Phases    ON Phases.LanguageID    = Languages.LanguageID
WHERE Programs.Program   = _Program
AND   Languages.Language = _Language
AND   Phases.Phase       = _Phase
FOR UPDATE OF Programs;

UPDATE Programs
SET PhaseID = _PhaseID
WHERE ProgramID = _ProgramID
RETURNING TRUE INTO STRICT _OK;

RETURN TRUE;
END;
$$;
