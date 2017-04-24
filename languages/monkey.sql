SET search_path TO soft, public;

SELECT New_Language(
    _Language              := 'monkey',
    _LogSeverity           := 'NOTICE',
    _ImplicitReturnValues  := TRUE,
    _StatementReturnValues := TRUE,
    _VariableBinding       := 'CAPTURE_BY_REFERENCE'
);
\ir monkey/node_types.sql

SELECT New_Phase(_Language := 'monkey', _Phase := 'TOKENIZE');
SELECT New_Phase(_Language := 'monkey', _Phase := 'DISCARD');
SELECT New_Phase(_Language := 'monkey', _Phase := 'PARSE');
SELECT New_Phase(_Language := 'monkey', _Phase := 'REDUCE');
SELECT New_Phase(_Language := 'monkey', _Phase := 'MAP_VARIABLES');
SELECT New_Phase(_Language := 'monkey', _Phase := 'MAP_FUNCTIONS');
SELECT New_Phase(_Language := 'monkey', _Phase := 'EVAL');

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:294',
    _SourceCode    := $$fn(x) { x; }(5)$$,
    _ExpectedType  := 'integer'::regtype,
    _ExpectedValue := '5'
);


/*

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:294',
    _SourceCode    := $$fn(x) { x; }(5)$$,
    _ExpectedType  := 'integer'::regtype,
    _ExpectedValue := '5'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'fibonacci',
    _SourceCode    := $$
        let fibonacci = fn(x) {
            if (x == 0) {
                0
            } else if (x == 1) {
                1
            } else {
                fibonacci(x - 1) + fibonacci(x - 2)
            }
        };
        fibonacci(3);
    $$,
    _ExpectedType  := 'integer'::regtype,
    _ExpectedValue := '2'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'factorial',
    _SourceCode    := $$
        let factorial = fn(n) {
            if (n == 0) {
                1
            } else {
                n * factorial(n - 1)
            }
        };
        factorial(5);
    $$,
    _ExpectedType  := 'integer'::regtype,
    _ExpectedValue := '120'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:289',
    _SourceCode    := $$let identity = fn(x) { x; }; identity(5);$$,
    _ExpectedType  := 'integer'::regtype,
    _ExpectedValue := '5'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:290',
    _SourceCode    := $$let identity = fn(x) { return x; }; identity(5);$$,
    _ExpectedType  := 'integer'::regtype,
    _ExpectedValue := '5'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:291',
    _SourceCode    := $$let double = fn(x) { x * 2; }; double(5);$$,
    _ExpectedType  := 'integer'::regtype,
    _ExpectedValue := '10'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:292',
    _SourceCode    := $$let add = fn(x, y) { x + y; }; add(5, 5);$$,
    _ExpectedType  := 'integer'::regtype,
    _ExpectedValue := '10'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:293',
    _SourceCode    := $$let add = fn(x, y) { x + y; }; add(5 + 5, add(5, 5));$$,
    _ExpectedType  := 'integer'::regtype,
    _ExpectedValue := '20'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:294',
    _SourceCode    := $$fn(x) { x; }(5)$$,
    _ExpectedType  := 'integer'::regtype,
    _ExpectedValue := '5'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:303',
    _SourceCode    := $$
        let first = 10;
        let second = 10;
        let third = 10;
        
        let ourFunction = fn(first) {
          let second = 20;
        
          first + second + third;
        };
        
        ourFunction(20) + first + second;
    $$,
    _ExpectedType  := 'integer'::regtype,
    _ExpectedValue := '70'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:321',
    _SourceCode    := $$
        let newAdder = fn(x) {
          fn(y) { x + y };
        };
        
        let addTwo = newAdder(2);
        addTwo(2);
    $$,
    _ExpectedType  := 'integer'::regtype,
    _ExpectedValue := '4'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:332',
    _SourceCode    := $$"Hello World!"$$,
    _ExpectedType  := 'text'::regtype,
    _ExpectedValue := 'Hello World!'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:346',
    _SourceCode    := $$"Hello" + " " + "World!"$$,
    _ExpectedType  := 'text'::regtype,
    _ExpectedValue := 'Hello World!'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:364',
    _SourceCode    := $$len("")$$,
    _ExpectedType  := 'integer'::regtype,
    _ExpectedValue := '0'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:365',
    _SourceCode    := $$len("four")$$,
    _ExpectedType  := 'integer'::regtype,
    _ExpectedValue := '4'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:366',
    _SourceCode    := $$len("hello world")$$,
    _ExpectedType  := 'integer'::regtype,
    _ExpectedValue := '11'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:367',
    _SourceCode    := $$len(1)$$,
    _ExpectedError := 'function EVAL.LENGTH_EXPRESSION(integer) does not exist'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:368',
    _SourceCode    := $$len("one", "two")$$,
    _ExpectedLog   := 'PARSE ERROR INVALID_EXPRESSION'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'arrays',
    _SourceCode    := $$
        let x = [10, 10+5, [2+3,30]];
        x[2-1]
    $$,
    _ExpectedType  := 'integer'::regtype,
    _ExpectedValue := '15'
);

*/