CREATE OR REPLACE FUNCTION New_Language(
_Language              text,
_LogSeverity           severity,
_ImplicitReturnValues  boolean,
_StatementReturnValues boolean,
_VariableBinding       variablebinding,
_ZeroBasedNumbering    boolean
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_LanguageID integer;
BEGIN

INSERT INTO Languages ( Language,  LogSeverity,  ImplicitReturnValues,  StatementReturnValues,  VariableBinding,  ZeroBasedNumbering)
VALUES                (_Language, _LogSeverity, _ImplicitReturnValues, _StatementReturnValues, _VariableBinding, _ZeroBasedNumbering)
RETURNING    LanguageID
INTO STRICT _LanguageID;

RETURN _LanguageID;

END;
$$;
