SET search_path TO soft, public, pg_temp;

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'test',
    _SourceCode    := $$
        let foo = fn(z) {
            2*z
        };
        let bar = fn(x,y) {
            10*x(y+1)
        };
        bar(foo,3)
    $$,
    _ExpectedType  := 'integer'::regtype,
    _ExpectedValue := '80'
);

/*


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
        loop {
            fibonacci(2);
        }
    $$,
    _ExpectedType  := 'integer'::regtype,
    _ExpectedValue := '1'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'anders_grandlund_1',
    _SourceCode    := $$
        let f = fn(x) {
            2*x
        };
        let g = fn(x) {
            x+1
        };
        f(g(7));
        f(g(4))
    $$,
    _ExpectedType  := 'integer'::regtype,
    _ExpectedValue := '10'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'anders_grandlund_1',
    _SourceCode    := $$
        let f = fn(x) {
            2*x
        };
        let g = fn(x) {
            x+1
        };
        f(g(7))
    $$,
    _ExpectedType  := 'integer'::regtype,
    _ExpectedValue := '16'
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