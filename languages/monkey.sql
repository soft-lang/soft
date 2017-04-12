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
let x = 10;
let foo = fn(a,b) {
    let c = a+b;
    return c;
    let d = 10;
    return d;
};
let y = 2*x*foo(20,30);
return y;
$SRC$);

/*

let rec = fn(i,max,value) {
    if (i == max) {
        return value;
    } else {
        return rec(i+1,max,value*i);
    }
};
let x = rec(0,10,0);

let fibonacci = fn(x) {
    if (x == 1) {
        1
    } else {
        return fibonacci(x - 1) + fibonacci(x - 2)
    }
};


*/