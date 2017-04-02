CREATE OR REPLACE FUNCTION New_Language(
_Language    text,
_LogSeverity severity DEFAULT 'DEBUG3'::severity
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_LanguageID integer;
BEGIN

INSERT INTO Languages (Language, LogSeverity) VALUES (_Language, _LogSeverity) RETURNING LanguageID INTO STRICT _LanguageID;

RETURN _LanguageID;

END;
$$;
