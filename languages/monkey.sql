SET search_path TO soft, public, pg_temp;

SELECT New_Language(
    _Language              := 'monkey',
    _LogSeverity           := 'DEBUG5',
    _ImplicitReturnValues  := TRUE,
    _StatementReturnValues := TRUE,
    _VariableBinding       := 'CAPTURE_BY_REFERENCE',
    _ZeroBasedNumbering    := TRUE
);

SELECT New_Phase(_Language := 'monkey', _Phase := 'TOKENIZE');
SELECT New_Phase(_Language := 'monkey', _Phase := 'DISCARD');
SELECT New_Phase(_Language := 'monkey', _Phase := 'PARSE');
SELECT New_Phase(_Language := 'monkey', _Phase := 'REDUCE');
SELECT New_Phase(_Language := 'monkey', _Phase := 'MAP_VARIABLES');
SELECT New_Phase(_Language := 'monkey', _Phase := 'EVAL');
