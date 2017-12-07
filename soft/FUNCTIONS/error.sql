CREATE OR REPLACE FUNCTION Error(
_NodeID    integer,
_ErrorType text,
_ErrorInfo hstore
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_Severity severity;
_Message  text;
BEGIN
SELECT
    ErrorTypes.Severity,
    Interpolate(
        _Text      := ErrorTypes.Message,
        _ErrorInfo := _ErrorInfo,
        _Sigil     := ErrorTypes.Sigil
    )
INTO
    _Severity,
    _Message
FROM Nodes
INNER JOIN Programs   ON Programs.ProgramID    = Nodes.ProgramID
INNER JOIN ErrorTypes ON ErrorTypes.LanguageID = Programs.LanguageID
WHERE Nodes.NodeID         = _NodeID
AND   ErrorTypes.ErrorType = _ErrorType;

RETURN Log(
    _NodeID    := _NodeID,
    _Severity  := COALESCE(_Severity,'ERROR'),
    _Message   := _Message,
    _ErrorType := _ErrorType,
    _ErrorInfo := _ErrorInfo
);
END;
$$;
