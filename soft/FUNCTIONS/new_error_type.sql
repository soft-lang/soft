CREATE OR REPLACE FUNCTION New_Error_Type(
_Language  text,
_ErrorType text,
_Severity  severity,
_Message   text,
_Sigil     char DEFAULT NULL
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_ErrorTypeID integer;
_LanguageID  integer;
BEGIN
SELECT LanguageID INTO STRICT _LanguageID FROM Languages WHERE Language = _Language;

INSERT INTO ErrorTypes ( LanguageID,  ErrorType,  Severity,  Message,  Sigil)
VALUES                 (_LanguageID, _ErrorType, _Severity, _Message, _Sigil)
RETURNING    ErrorTypeID
INTO STRICT _ErrorTypeID;

RETURN _ErrorTypeID;
END;
$$;
