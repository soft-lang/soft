CREATE OR REPLACE FUNCTION soft.New_Language(_Language text)
RETURNS integer
LANGUAGE plpgsql
SET search_path TO soft, public, pg_temp
AS $$
DECLARE
_LanguageID integer;
BEGIN
INSERT INTO Languages (Language) VALUES (_Language) RETURNING LanguageID INTO STRICT _LanguageID;
RETURN _LanguageID;
END;
$$;
