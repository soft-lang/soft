SET search_path TO soft, public, pg_temp;

SELECT New_Language(
    _Language              := 'monkey',
    _LogSeverity           := 'NOTICE',
    _ImplicitReturnValues  := TRUE,
    _StatementReturnValues := TRUE,
    _VariableBinding       := 'CAPTURE_BY_VALUE',
    _ZeroBasedNumbering    := TRUE,
   	_TruthyNonBooleans     := TRUE,
   	_ArrayOutOfBoundsError := FALSE,
   	_MissingHashKeyError   := FALSE
);

SELECT New_Phase(_Language := 'monkey', _Phase := 'TOKENIZE');
SELECT New_Phase(_Language := 'monkey', _Phase := 'DISCARD');
SELECT New_Phase(_Language := 'monkey', _Phase := 'PARSE');
SELECT New_Phase(_Language := 'monkey', _Phase := 'REDUCE');
SELECT New_Phase(_Language := 'monkey', _Phase := 'MAP_VARIABLES');
SELECT New_Phase(_Language := 'monkey', _Phase := 'EVAL');

SELECT New_Built_In_Function(_Language := 'monkey', _Identifier := 'len',   _ImplementationFunction := 'LENGTH');
SELECT New_Built_In_Function(_Language := 'monkey', _Identifier := 'first', _ImplementationFunction := 'FIRST');
SELECT New_Built_In_Function(_Language := 'monkey', _Identifier := 'rest',  _ImplementationFunction := 'REST');
SELECT New_Built_In_Function(_Language := 'monkey', _Identifier := 'push',  _ImplementationFunction := 'PUSH');
SELECT New_Built_In_Function(_Language := 'monkey', _Identifier := 'last',  _ImplementationFunction := 'LAST');
SELECT New_Built_In_Function(_Language := 'monkey', _Identifier := 'puts',  _ImplementationFunction := 'PUTS');
