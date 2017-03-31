CREATE OR REPLACE FUNCTION New_Language(_Language text)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_LanguageID integer;
BEGIN

INSERT INTO Languages (Language) VALUES (_Language) RETURNING LanguageID INTO STRICT _LanguageID;

RETURN _LanguageID;

END;
$$;
