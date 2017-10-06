CREATE OR REPLACE FUNCTION Run_Tests(_Language text)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_Program text;
_TestResult boolean;
BEGIN

_TestResult := TRUE;

FOR _Program IN
SELECT Programs.Program FROM Tests
INNER JOIN Programs  ON Programs.ProgramID   = Tests.ProgramID
INNER JOIN Languages ON Languages.LanguageID = Programs.LanguageID
WHERE Languages.Language = _Language
ORDER BY Tests.TestID
LOOP
    IF Run_Test(_Language, _Program) IS FALSE THEN
        _TestResult := FALSE;
    END IF;
END LOOP;

RETURN _TestResult;
END;
$$;
