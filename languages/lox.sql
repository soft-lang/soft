SET search_path TO soft, public, pg_temp;

\set ON_ERROR_STOP 1
\set language lox

BEGIN;

TRUNCATE TABLE Languages CASCADE;

SELECT New_Language(
    _Language              := :'language',
    _VariableBinding       := 'CAPTURE_BY_VALUE',
    _ImplicitReturnValues  := TRUE,
    _StatementReturnValues := TRUE,
    _ZeroBasedNumbering    := TRUE,
    _TruthyNonBooleans     := TRUE,
    _NilIfArrayOutOfBounds := TRUE,
    _NilIfMissingHashKey   := TRUE
);

SELECT New_Phase(_Language := :'language', _Phase := 'TOKENIZE');
SELECT New_Phase(_Language := :'language', _Phase := 'DISCARD');
SELECT New_Phase(_Language := :'language', _Phase := 'PARSE');
SELECT New_Phase(_Language := :'language', _Phase := 'REDUCE');
SELECT New_Phase(_Language := :'language', _Phase := 'MAP_VARIABLES', _SaveDOTIR := TRUE);
SELECT New_Phase(_Language := :'language', _Phase := 'SHORT_CIRCUIT', _SaveDOTIR := TRUE);
SELECT New_Phase(_Language := :'language', _Phase := 'EVAL',          _SaveDOTIR := TRUE);

SELECT New_Built_In_Function(_Language := :'language', _Identifier := 'len',   _ImplementationFunction := 'LENGTH');
SELECT New_Built_In_Function(_Language := :'language', _Identifier := 'first', _ImplementationFunction := 'FIRST');
SELECT New_Built_In_Function(_Language := :'language', _Identifier := 'rest',  _ImplementationFunction := 'REST');
SELECT New_Built_In_Function(_Language := :'language', _Identifier := 'push',  _ImplementationFunction := 'PUSH');
SELECT New_Built_In_Function(_Language := :'language', _Identifier := 'last',  _ImplementationFunction := 'LAST');
SELECT New_Built_In_Function(_Language := :'language', _Identifier := 'puts',  _ImplementationFunction := 'PUTS');

\ir load-nodetypes.sql

\ir truthy-non-booleans.sql

\ir :language/test.sql

CREATE OR REPLACE FUNCTION lox(
_SourceCode  text,
_LogSeverity severity DEFAULT 'NOTICE'
) RETURNS TABLE (
OK             boolean,
Error          text,
PrimitiveType  regtype,
PrimitiveValue text
)
LANGUAGE sql
AS $$
SELECT * FROM Soft(
    _Language    := 'lox',
    _SourceCode  := $1,
    _LogSeverity := $2
)
$$;

COMMIT;

