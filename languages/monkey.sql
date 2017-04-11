SET search_path TO soft, public;

SELECT New_Language(_Language := 'monkey', _LogSeverity := 'DEBUG5');
\ir monkey/node_types.sql

SELECT New_Phase(_Language := 'monkey', _Phase := 'TOKENIZE');
SELECT New_Phase(_Language := 'monkey', _Phase := 'DISCARD');
SELECT New_Phase(_Language := 'monkey', _Phase := 'PARSE');
SELECT New_Phase(_Language := 'monkey', _Phase := 'REDUCE');
SELECT New_Phase(_Language := 'monkey', _Phase := 'MAP_VARIABLES');
SELECT New_Phase(_Language := 'monkey', _Phase := 'MAP_ALLOCA');
SELECT New_Phase(_Language := 'monkey', _Phase := 'MAP_FUNCTIONS');
SELECT New_Phase(_Language := 'monkey', _Phase := 'EVAL');

SELECT New_Program(_Language := 'monkey', _Program := 'test');

SELECT New_Node(_Program := 'test', _NodeType := 'SOURCE_CODE', _TerminalType := 'text'::regtype, _TerminalValue := $SRC$
let x = 1+2+3-4**5+6*(8+9*10);
let y = 4+5*(6-7);
$SRC$);
