CREATE OR REPLACE FUNCTION New_Built_In_Function(
_Language               text,
_Identifier             text,
_ImplementationFunction text
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_LanguageID        integer;
_BuiltInFunctionID integer;
BEGIN

SELECT       LanguageID
INTO STRICT _LanguageID
FROM Languages
WHERE Language = _Language;

INSERT INTO BuiltInFunctions ( LanguageID,  Identifier,  ImplementationFunction)
VALUES                       (_LanguageID, _Identifier, _ImplementationFunction)
RETURNING    BuiltInFunctionID
INTO STRICT _BuiltInFunctionID;

RETURN _BuiltInFunctionID;

END;
$$;
