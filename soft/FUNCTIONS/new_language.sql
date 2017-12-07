CREATE OR REPLACE FUNCTION New_Language(
_Language                    text,
_VariableBinding             variablebinding,
_ImplicitReturnValues        boolean,
_StatementReturnValues       boolean,
_ZeroBasedNumbering          boolean,
_TruthyNonBooleans           boolean,
_NilIfArrayOutOfBounds       boolean,
_NilIfMissingHashKey         boolean,
_StripZeroes                 boolean,
_NegativeZeroes              boolean,
_ClassInitializerName        text      DEFAULT NULL,
_Translation                 hstore    DEFAULT NULL
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_LanguageID integer;
BEGIN

INSERT INTO Languages ( Language,  ImplicitReturnValues,  StatementReturnValues,  VariableBinding,  ZeroBasedNumbering,  TruthyNonBooleans,  NilIfArrayOutOfBounds,  NilIfMissingHashKey,  StripZeroes,  NegativeZeroes,  ClassInitializerName,  Translation)
VALUES                (_Language, _ImplicitReturnValues, _StatementReturnValues, _VariableBinding, _ZeroBasedNumbering, _TruthyNonBooleans, _NilIfArrayOutOfBounds, _NilIfMissingHashKey, _StripZeroes, _NegativeZeroes, _ClassInitializerName, _Translation)
RETURNING    LanguageID
INTO STRICT _LanguageID;

RETURN _LanguageID;

END;
$$;
