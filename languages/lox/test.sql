SET search_path TO soft, public, pg_temp;

\set language lox

SELECT New_Test(
    _Language      := :'language',
    _Program       := 'fibonacci',
    _SourceCode    := $$
        fun fibonacci(x) {
            if (x == 0) {
                return 0;
            } else if (x == 1) {
                return 1;
            } else {
                return fibonacci(x - 1) + fibonacci(x - 2);
            }
        }
        print fibonacci(5);
    $$,
    _ExpectedSTDOUT := ARRAY['5']
);

-- CLOSURE

SELECT New_Test(
    _Language       := :'language',
    _Program        := 'closure/close_over_method_parameter.lox',
    _SourceCode     := $$
var f;

class Foo {
  method(param) {
    fun f_() {
      print param;
    }
    f = f_;
  }
}

Foo().method("param");
f(); // expect: param
$$,
    _ExpectedSTDOUT := ARRAY['param']
);

SELECT New_Test(
    _Language       := :'language',
    _Program        := 'closure/close_over_later_variable.lox',
    _SourceCode     := $$
fun f() {
  var a = "a";
  var b = "b";
  fun g() {
    print b; // expect: b
    print a; // expect: a
  }
  g();
}
f();
$$,
    _ExpectedSTDOUT := ARRAY['b','a']
);

SELECT New_Test(
    _Language       := :'language',
    _Program        := 'closure/close_over_function_parameter.lox',
    _SourceCode     := $$
var f;

fun foo(param) {
  fun f_() {
    print param;
  }
  f = f_;
}
foo("param");

f(); // expect: param
$$,
    _ExpectedSTDOUT := ARRAY['param']
);

SELECT New_Test(
    _Language       := :'language',
    _Program        := 'closure/assign_to_shadowed_later.lox',
    _SourceCode     := $$
var a = "global";

{
  fun assign() {
    a = "assigned";
  }

  var a = "inner";
  assign();
  print a; // expect: inner
}

print a; // expect: assigned
$$,
    _ExpectedSTDOUT := ARRAY['inner','assigned']
);

SELECT New_Test(
    _Language       := :'language',
    _Program        := 'closure/assign_to_closure.lox',
    _SourceCode     := $$
var f;
var g;

{
  var local = "local";
  fun f_() {
    print local;
    local = "after f";
    print local;
  }
  f = f_;

  fun g_() {
    print local;
    local = "after g";
    print local;
  }
  g = g_;
}

f();
// expect: local
// expect: after f

g();
// expect: after f
// expect: after g
$$,
    _ExpectedSTDOUT := ARRAY['local','after f','after f','after g']
);


-- CALL
SELECT New_Test(
    _Language       := :'language',
    _Program        := 'call/string.lox',
    _SourceCode     := $$
"str"(); // expect runtime error: Can only call functions and classes.
$$,
    _ExpectedLog := 'PARSE ERROR CAN_ONLY_CALL_FUNCTIONS_AND_CLASSES'
);

SELECT New_Test(
    _Language       := :'language',
    _Program        := 'call/object.lox',
    _SourceCode     := $$
class Foo {}

var foo = Foo();
foo(); // expect runtime error: Can only call functions and classes.
$$,
    _ExpectedLog := 'PARSE ERROR CAN_ONLY_CALL_FUNCTIONS_AND_CLASSES'
);

SELECT New_Test(
    _Language       := :'language',
    _Program        := 'call/num.lox',
    _SourceCode     := $$
123(); // expect runtime error: Can only call functions and classes.
$$,
    _ExpectedLog := 'PARSE ERROR CAN_ONLY_CALL_FUNCTIONS_AND_CLASSES'
);

SELECT New_Test(
    _Language       := :'language',
    _Program        := 'call/nil.lox',
    _SourceCode     := $$
nil(); // expect runtime error: Can only call functions and classes.
$$,
    _ExpectedLog := 'PARSE ERROR CAN_ONLY_CALL_FUNCTIONS_AND_CLASSES'
);

SELECT New_Test(
    _Language       := :'language',
    _Program        := 'call/bool.lox',
    _SourceCode     := $$
true(); // expect runtime error: Can only call functions and classes.
$$,
    _ExpectedLog := 'PARSE ERROR CAN_ONLY_CALL_FUNCTIONS_AND_CLASSES'
);

-- BOOL

SELECT New_Test(
    _Language       := :'language',
    _Program        := 'bool/not.lox',
    _SourceCode     := $$
print !true;    // expect: false
print !false;   // expect: true
print !!true;   // expect: true
$$,
    _ExpectedSTDOUT := ARRAY['false','true','true']
);

SELECT New_Test(
    _Language       := :'language',
    _Program        := 'bool/equality.lox',
    _SourceCode     := $$
print true == true;    // expect: true
print true == false;   // expect: false
print false == true;   // expect: false
print false == false;  // expect: true

// Not equal to other types.
print true == 1;        // expect: false
print false == 0;       // expect: false
print true == "true";   // expect: false
print false == "false"; // expect: false
print false == "";      // expect: false

print true != true;    // expect: false
print true != false;   // expect: true
print false != true;   // expect: true
print false != false;  // expect: false

// Not equal to other types.
print true != 1;        // expect: true
print false != 0;       // expect: true
print true != "true";   // expect: true
print false != "false"; // expect: true
print false != "";      // expect: true
$$,
    _ExpectedSTDOUT := ARRAY['true','false','false','true','false','false','false','false','false','false','true','true','false','true','true','true','true','true']
);

-- BLOCK

SELECT New_Test(
    _Language       := :'language',
    _Program        := 'block/empty.lox',
    _SourceCode     := $$
{} // By itself.

// In a statement.
if (true) {}
if (false) {} else {}

print "ok"; // expect: ok
$$,
    _ExpectedSTDOUT := ARRAY['ok']
);

SELECT New_Test(
    _Language       := :'language',
    _Program        := 'block/scope.lox',
    _SourceCode     := $$
var a = "outer";

{
  var a = "inner";
  print a; // expect: inner
}

print a; // expect: outer
$$,
    _ExpectedSTDOUT := ARRAY['inner','outer']
);

-- ASSIGNMENT

SELECT New_Test(
    _Language       := :'language',
    _Program        := 'assignment/associativity.lox',
    _SourceCode     := $$
var a = "a";
var b = "b";
var c = "c";

// Assignment is right-associative.
a = b = c;
print a; // expect: c
print b; // expect: c
print c; // expect: c
$$,
    _ExpectedSTDOUT := ARRAY['c','c','c']
);

SELECT New_Test(
    _Language       := :'language',
    _Program        := 'assignment/global.lox',
    _SourceCode     := $$
var a = "before";
print a; // expect: before

a = "after";
print a; // expect: after

print a = "arg"; // expect: arg
print a; // expect: arg
$$,
    _ExpectedSTDOUT := ARRAY['before','after','arg','arg']
);

SELECT New_Test(
    _Language       := :'language',
    _Program        := 'assignment/grouping.lox',
    _SourceCode     := $$
var a = "a";
(a) = "value"; // Error at '=': Invalid assignment target.
$$,
    _ExpectedLog := 'VALIDATE ERROR ASSIGNMENT'
);

SELECT New_Test(
    _Language       := :'language',
    _Program        := 'assignment/infix_operator.lox',
    _SourceCode     := $$
var a = "a";
var b = "b";
a + b = "value"; // Error at '=': Invalid assignment target.
$$,
    _ExpectedLog := 'VALIDATE ERROR ASSIGNMENT'
);

SELECT New_Test(
    _Language       := :'language',
    _Program        := 'assignment/local.lox',
    _SourceCode     := $$
{
  var a = "before";
  print a; // expect: before

  a = "after";
  print a; // expect: after

  print a = "arg"; // expect: arg
  print a; // expect: arg
}
$$,
    _ExpectedSTDOUT := ARRAY['before','after','arg','arg']
);

SELECT New_Test(
    _Language       := :'language',
    _Program        := 'assignment/prefix_operator.lox',
    _SourceCode     := $$
var a = "a";
!a = "value"; // Error at '=': Invalid assignment target.
$$,
    _ExpectedLog := 'VALIDATE ERROR ASSIGNMENT'
);

SELECT New_Test(
    _Language       := :'language',
    _Program        := 'assignment/syntax.lox',
    _SourceCode     := $$
// Assignment on RHS of variable.
var a = "before";
var c = a = "var";
print a; // expect: var
print c; // expect: var
$$,
    _ExpectedSTDOUT := ARRAY['var','var']
);

SELECT New_Test(
    _Language       := :'language',
    _Program        := 'assignment/to_this.lox',
    _SourceCode     := $$
class Foo {
  Foo() {
    this = "value"; // Error at '=': Invalid assignment target.
  }
}

Foo();
$$,
    _ExpectedLog := 'VALIDATE ERROR ASSIGNMENT'
);

SELECT New_Test(
    _Language       := :'language',
    _Program        := 'assignment/undefined.lox',
    _SourceCode     := $$
unknown = "what"; // expect runtime error: Undefined variable 'unknown'.
$$,
    _ExpectedLog := 'MAP_VARIABLES ERROR IDENTIFIER'
);

/*

SELECT New_Test(
    _Language       := :'language',
    _Program        := 'if/logical_operator.lox:1.'||N,
    _SourceCode     := LogicalOperator1.T[N][1],
    _ExpectedSTDOUT := ARRAY[LogicalOperator1.T[N][2]]
) FROM (
    SELECT ARRAY[
        -- Note: These tests implicitly depend on ints being truthy.

        -- Return the first non-true argument.
        ['print false and 1;', 'false'],
        ['print true and 1;' ,'1'],
        ['print 1 and 2 and false;', 'false'],

        -- Return the last argument if all are true.
        ['print 1 and true;', 'true'],
        ['print 1 and 2 and 3;', '3']
    ] AS T
) AS LogicalOperator1
CROSS JOIN generate_series(1,array_length(LogicalOperator1.T,1)) AS N;

SELECT New_Test(
    _Language       := :'language',
    _Program        := 'if/logical_operator.lox:2',
    -- Short-circuit at the first false argument.
    _SourceCode     := $$
        var a = "before";
        var b = "before";
        (a = true) and
            (b = false) and
            (a = "bad");
        print a;
        print b;
    $$,
    _ExpectedSTDOUT := ARRAY['true','false']
);

SELECT New_Test(
    _Language       := :'language',
    _Program        := 'if/truth.lox:'||N,
    _SourceCode     := Truth.T[N][1],
    _ExpectedSTDOUT := ARRAY[Truth.T[N][2]]
) FROM (
    SELECT ARRAY[
        -- False and nil are false.
        ['if (false) print "bad"; else print "false";', 'false'],
        ['if (nil) print "bad"; else print "nil";', 'nil'],

        -- Everything else is true.
        ['if (true) print true;', 'true'],
        ['if (0) print 0;', '0'],
        ['if ("") print "empty";', 'empty']
    ] AS T
) AS Truth
CROSS JOIN generate_series(1,array_length(Truth.T,1)) AS N;

SELECT New_Test(
    _Language       := :'language',
    _Program        := 'if/dangling_else.lox:'||N,
    _SourceCode     := DanglingElse.T[N][1],
    _ExpectedSTDOUT := ARRAY[DanglingElse.T[N][2]]
) FROM (
    SELECT ARRAY[
        -- A dangling else binds to the right-most if.
        ['if (true) if (false) print "bad"; else print "good";', 'good'],
        ['if (false) if (true) print "bad"; else print "bad";',  NULL]
    ] AS T
) AS DanglingElse
CROSS JOIN generate_series(1,array_length(DanglingElse.T,1)) AS N;

SELECT New_Test(
    _Language       := :'language',
    _Program        := 'if/if.lox:'||N,
    _SourceCode     := If.T[N][1],
    _ExpectedSTDOUT := ARRAY[If.T[N][2]]
) FROM (
    SELECT ARRAY[
        -- Evaluate the 'then' expression if the condition is true.
        ['if (true) print "good";', 'good'],
        ['if (false) print "bad";',  NULL],

        -- Allow block body.
        ['if (true) { print "block"; }', 'block'],

        -- // Assignment in if condition.
        ['var a = false;
         if (a = true) print a;',  'true']
    ] AS T
) AS If
CROSS JOIN generate_series(1,array_length(If.T,1)) AS N;

SELECT New_Test(
    _Language       := :'language',
    _Program        := 'operator/equals.lox:'||N,
    _SourceCode     := OperatorEquals.T[N][1],
    _ExpectedSTDOUT := ARRAY[OperatorEquals.T[N][2]]
) FROM (
    SELECT ARRAY[
        ['print nil == nil;',     'true'],
        ['print true == true;',   'true'],
        ['print true == false;',  'false'],
        ['print 1 == 1;',         'true'],
        ['print 1 == 2;',         'false'],
        ['print "str" == "str";', 'true'],
        ['print "str" == "ing";', 'false'],
        ['print nil == false;',   'false'],
        ['print false == 0;',     'false'],
        ['print 0 == "0";',       'false']
    ] AS T
) AS OperatorEquals
CROSS JOIN generate_series(1,array_length(OperatorEquals.T,1)) AS N;

*/