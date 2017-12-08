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
_ReturnFromTopLevel          boolean,
_ParametersOwnScope          boolean,
_ClassInitializerName        text      DEFAULT NULL,
_Translation                 hstore    DEFAULT NULL,
_MaxParameters               integer   DEFAULT NULL
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_LanguageID integer;
BEGIN

INSERT INTO Languages ( Language,  ImplicitReturnValues,  StatementReturnValues,  VariableBinding,  ZeroBasedNumbering,  TruthyNonBooleans,  NilIfArrayOutOfBounds,  NilIfMissingHashKey,  StripZeroes,  NegativeZeroes,  ReturnFromTopLevel,  ParametersOwnScope,  ClassInitializerName,  Translation,  MaxParameters)
VALUES                (_Language, _ImplicitReturnValues, _StatementReturnValues, _VariableBinding, _ZeroBasedNumbering, _TruthyNonBooleans, _NilIfArrayOutOfBounds, _NilIfMissingHashKey, _StripZeroes, _NegativeZeroes, _ReturnFromTopLevel, _ParametersOwnScope, _ClassInitializerName, _Translation, _MaxParameters)
RETURNING    LanguageID
INTO STRICT _LanguageID;

RETURN _LanguageID;

END;
$$;
