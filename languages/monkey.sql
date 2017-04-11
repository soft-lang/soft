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
let x = fn(a,b) {
    let z = fn(c,d) {
        c*d;
    };
    return z(10,20);
};
let y = x(1,2);
y;
$SRC$);
