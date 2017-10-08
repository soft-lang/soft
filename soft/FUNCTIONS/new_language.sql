CREATE OR REPLACE FUNCTION New_Language(
_Language              text,
_LogSeverity           severity,
_VariableBinding       variablebinding,
_ImplicitReturnValues  boolean,
_StatementReturnValues boolean,
_ZeroBasedNumbering    boolean,
_TruthyNonBooleans     boolean,
_NilIfArrayOutOfBounds boolean,
_NilIfMissingHashKey   boolean
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_LanguageID integer;
BEGIN

INSERT INTO Languages ( Language,  LogSeverity,  ImplicitReturnValues,  StatementReturnValues,  VariableBinding,  ZeroBasedNumbering,  TruthyNonBooleans,  NilIfArrayOutOfBounds,  NilIfMissingHashKey)
VALUES                (_Language, _LogSeverity, _ImplicitReturnValues, _StatementReturnValues, _VariableBinding, _ZeroBasedNumbering, _TruthyNonBooleans, _NilIfArrayOutOfBounds, _NilIfMissingHashKey)
RETURNING    LanguageID
INTO STRICT _LanguageID;

RETURN _LanguageID;

END;
$$;
