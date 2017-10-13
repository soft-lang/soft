SET search_path TO soft, public, pg_temp;

\set ON_ERROR_STOP 1
\set language monkey

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
SELECT New_Phase(_Language := :'language', _Phase := 'EVAL',          _SaveDOTIR := TRUE);

SELECT New_Built_In_Function(_Language := :'language', _Identifier := 'len',   _ImplementationFunction := 'LENGTH');
SELECT New_Built_In_Function(_Language := :'language', _Identifier := 'first', _ImplementationFunction := 'FIRST');
SELECT New_Built_In_Function(_Language := :'language', _Identifier := 'rest',  _ImplementationFunction := 'REST');
SELECT New_Built_In_Function(_Language := :'language', _Identifier := 'push',  _ImplementationFunction := 'PUSH');
SELECT New_Built_In_Function(_Language := :'language', _Identifier := 'last',  _ImplementationFunction := 'LAST');
SELECT New_Built_In_Function(_Language := :'language', _Identifier := 'puts',  _ImplementationFunction := 'PUTS');

\ir load-nodetypes.sql

\ir :language/test.sql

COMMIT;

