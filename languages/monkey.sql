SET search_path TO soft, public;

SELECT New_Language(
    _Language             := 'monkey',
    _LogSeverity          := 'DEBUG5',
    _ImplicitReturnValues := TRUE
);
\ir monkey/node_types.sql

SELECT New_Phase(_Language := 'monkey', _Phase := 'TOKENIZE');
SELECT New_Phase(_Language := 'monkey', _Phase := 'DISCARD');
SELECT New_Phase(_Language := 'monkey', _Phase := 'PARSE');
SELECT New_Phase(_Language := 'monkey', _Phase := 'REDUCE');
SELECT New_Phase(_Language := 'monkey', _Phase := 'MAP_VARIABLES');
SELECT New_Phase(_Language := 'monkey', _Phase := 'MAP_FUNCTIONS');
SELECT New_Phase(_Language := 'monkey', _Phase := 'EVAL');

SELECT New_Program(_Language := 'monkey', _Program := 'test');

SELECT New_Node(_Program := 'test', _NodeType := 'SOURCE_CODE', _TerminalType := 'text'::regtype, _TerminalValue := $SRC$

$SRC$);

/*

let fibonacci = fn(x) {
    if (x == 0) {
        return 0;
    } else if (x == 1) {
        return 1;
    } else {
        return fibonacci(x - 2)+fibonacci(x - 1);
    }
};
let foo = fibonacci(7);
return foo;

let add = fn(x, y) { x + y; }; add(5 + 5, add(5, 5));



let foo = fn(x) {
    if (x == 2) {
        return 10;
    } else {
        return foo(x+1);
    }
};
let y = foo(0);
return y;




let x = 1+2*3;
let y = 4;
let z = 5;
let abc = x+y+z;


let fibonacci = fn(x) {
    if (x == 0) {
        return 0;
    } else if (x == 1) {
        return 1;
    } else {
        return fibonacci(x - 1) + fibonacci(x - 2);
    }
};
let foo = fibonacci(4);

return foo;

let cd = fn(x) {
    if (x == 2) {
        return 100;
    } else {
        return cd(x+1);
    }
};
let y = cd(0);
return y;



let foo = fn(x) {
    if (x == 1) {
        return x;
    } else {
        let a = foo(1);
        let b = foo(1);
        return a+b;
    }
};
let y = foo(2);
return y;



let foo = fn(x) {
    if (x == 3) {
        return x;
    } else {
        return foo(x+1);
    }
};
let z = foo(0);
return z;

let foo = fn(x) {
    return x;
};
let bar = fn(x,y) {
    return x*y;
};
let y = foo(10)+bar(3,2);
return y;


let foo = fn(x) {
    if (x == 3) {
        return x;
    } else {
        return foo(x+1);
    }
};
let y = foo(0);
return y;




*/