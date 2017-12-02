CREATE OR REPLACE FUNCTION New_Language(
_Language              text,
_VariableBinding       variablebinding,
_ImplicitReturnValues  boolean,
_StatementReturnValues boolean,
_ZeroBasedNumbering    boolean,
_TruthyNonBooleans     boolean,
_NilIfArrayOutOfBounds boolean,
_NilIfMissingHashKey   boolean,
_ClassInitializerName  text
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_LanguageID integer;
BEGIN

INSERT INTO Languages ( Language,  ImplicitReturnValues,  StatementReturnValues,  VariableBinding,  ZeroBasedNumbering,  TruthyNonBooleans,  NilIfArrayOutOfBounds,  NilIfMissingHashKey,  ClassInitializerName)
VALUES                (_Language, _ImplicitReturnValues, _StatementReturnValues, _VariableBinding, _ZeroBasedNumbering, _TruthyNonBooleans, _NilIfArrayOutOfBounds, _NilIfMissingHashKey, _ClassInitializerName)
RETURNING    LanguageID
INTO STRICT _LanguageID;

RETURN _LanguageID;

END;
$$;
