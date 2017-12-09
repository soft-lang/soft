CREATE OR REPLACE FUNCTION New_Error_Type(
_Language    text,
_ErrorType   text,
_Severity    severity,
_Phase       name DEFAULT NULL,
_NodeType    text DEFAULT NULL,
_NodePattern text DEFAULT NULL,
_Message     text DEFAULT NULL,
_Sigil       char DEFAULT NULL
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_ErrorTypeID integer;
_PhaseID     integer;
_NodeTypeID  integer;
_LanguageID  integer;
BEGIN
SELECT LanguageID INTO STRICT _LanguageID FROM Languages WHERE Language = _Language;

IF _Phase    IS NOT NULL THEN SELECT PhaseID    INTO STRICT _PhaseID    FROM Phases    WHERE LanguageID = _LanguageID AND Phase    = _Phase;    END IF;
IF _NodeType IS NOT NULL THEN SELECT NodeTypeID INTO STRICT _NodeTypeID FROM NodeTypes WHERE LanguageID = _LanguageID AND NodeType = _NodeType; END IF;

INSERT INTO ErrorTypes ( LanguageID,  ErrorType,  Severity,  PhaseID,  NodeTypeID,  NodePattern,  Message,  Sigil)
VALUES                 (_LanguageID, _ErrorType, _Severity, _PhaseID, _NodeTypeID, _NodePattern, _Message, _Sigil)
RETURNING    ErrorTypeID
INTO STRICT _ErrorTypeID;

RETURN _ErrorTypeID;
END;
$$;
