SET search_path TO soft, public, pg_temp;

\set language monkey

SELECT New_Test(
    _Language      := :'language',
    _Program       := 'fibonacci1',
    _SourceCode    := $$
        let fibonacci = fn(n,i,a,b) {
            if (i < n) {
                fibonacci(n, i+1, b, a+b)
            } else {
                b
            }
        };
        fibonacci(2,1,0,1);
    $$,
    _ExpectedType  := 'integer'::regtype,
    _ExpectedValue := '1',
    _LogSeverity   := 'DEBUG5'
);

SELECT New_Test(
    _Language      := :'language',
    _Program       := 'fibonacci2',
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
        fibonacci(2);
    $$,
    _ExpectedType  := 'integer'::regtype,
    _ExpectedValue := '1'
);

SELECT New_Test(
    _Language      := :'language',
    _Program       := 'evaluator_test.go:TestEvalIntegerExpression:'||N,
    _SourceCode    := TestEvalIntegerExpression.T[N][1],
    _ExpectedType  := 'integer',
    _ExpectedValue := TestEvalIntegerExpression.T[N][2]
) FROM (
    SELECT ARRAY[
        ['5',                                '5'],
        ['10',                              '10'],
        ['-5',                              '-5'],
        ['-10',                            '-10'],
        ['5 + 5 + 5 + 5 - 10',              '10'],
        ['2 * 2 * 2 * 2 * 2',               '32'],
        ['-50 + 100 + -50',                  '0'],
        ['5 * 2 + 10',                      '20'],
        ['5 + 2 * 10',                      '25'],
        ['20 + 2 * -10',                     '0'],
        ['50 / 2 * 2 + 10',                 '60'],
        ['2 * (5 + 10)',                    '30'],
        ['3 * 3 * 3 + 10',                  '37'],
        ['3 * (3 * 3) + 10',                '37'],
        ['(5 + 10 * 2 + 15 / 3) * 2 + -10', '50']
    ] AS T
) AS TestEvalIntegerExpression
CROSS JOIN generate_series(1,array_length(TestEvalIntegerExpression.T,1)) AS N;

SELECT New_Test(
    _Language      := :'language',
    _Program       := 'evaluator_test.go:TestEvalBooleanExpression:'||N,
    _SourceCode    := TestEvalBooleanExpression.T[N][1],
    _ExpectedType  := 'boolean',
    _ExpectedValue := TestEvalBooleanExpression.T[N][2]
) FROM (
    SELECT ARRAY[
        ['true',              'true'],
        ['false',            'false'],
        ['1 < 2',             'true'],
        ['1 > 2',            'false'],
        ['1 < 1',            'false'],
        ['1 > 1',            'false'],
        ['1 == 1',            'true'],
        ['1 != 1',           'false'],
        ['1 == 2',           'false'],
        ['1 != 2',            'true'],
        ['true == true',      'true'],
        ['false == false',    'true'],
        ['true == false',    'false'],
        ['true != false',     'true'],
        ['false != true',     'true'],
        ['(1 < 2) == true',   'true'],
        ['(1 < 2) == false', 'false'],
        ['(1 > 2) == true',  'false'],
        ['(1 > 2) == false' , 'true']
    ] AS T
) AS TestEvalBooleanExpression
CROSS JOIN generate_series(1,array_length(TestEvalBooleanExpression.T,1)) AS N;

SELECT New_Test(
    _Language      := :'language',
    _Program       := 'evaluator_test.go:TestBangOperator:'||N,
    _SourceCode    := TestBangOperator.T[N][1],
    _ExpectedType  := 'boolean',
    _ExpectedValue := TestBangOperator.T[N][2]
) FROM (
    SELECT ARRAY[
        ['!true',   'false'],
        ['!false',   'true'],
        ['!5',      'false'],
        ['!!true',   'true'],
        ['!!false', 'false'],
        ['!!5',      'true']
    ] AS T
) AS TestBangOperator
CROSS JOIN generate_series(1,array_length(TestBangOperator.T,1)) AS N;

SELECT New_Test(
    _Language      := :'language',
    _Program       := 'evaluator_test.go:TestIfElseExpressions:'||N,
    _SourceCode    := TestIfElseExpressions.T[N][1],
    _ExpectedType  := TestIfElseExpressions.T[N][2]::regtype,
    _ExpectedValue := TestIfElseExpressions.T[N][3]
) FROM (
    SELECT ARRAY[
        ['if (true) { 10 }',              'integer',  '10'],
        ['if (false) { 10 }',             'nil',     'nil'],
        ['if (1) { 10 }',                 'integer',  '10'],
        ['if (1 < 2) { 10 }',             'integer',  '10'],
        ['if (1 > 2) { 10 }',             'nil',     'nil'],
        ['if (1 > 2) { 10 } else { 20 }', 'integer',  '20'],
        ['if (1 < 2) { 10 } else { 20 }', 'integer',  '10']
    ] AS T
) AS TestIfElseExpressions
CROSS JOIN generate_series(1,array_length(TestIfElseExpressions.T,1)) AS N;

SELECT New_Test(
    _Language      := :'language',
    _Program       := 'evaluator_test.go:TestReturnStatements:'||N,
    _SourceCode    := TestReturnStatements.T[N][1],
    _ExpectedType  := 'integer',
    _ExpectedValue := TestReturnStatements.T[N][2]
) FROM (
    SELECT ARRAY[
        ['return 10;',                 '10'],
        ['return 10; 9;',              '10'],
        ['return 2 * 5; 9;',           '10'],
        ['9; return 2 * 5; 9;',        '10'],
        ['if (10 > 1) { return 10; }', '10'],
        ['if (10 > 1) {
            if (10 > 1) {
              return 10;
            }

            return 1;
          }',                          '10'],
        ['let f = fn(x) {
            return x;
            x + 10;
          };
          f(10);',                     '10'],
        ['let f = fn(x) {
             let result = x + 10;
             return result;
             return 10;
          };
          f(10);',                     '20']
    ] AS T
) AS TestReturnStatements
CROSS JOIN generate_series(1,array_length(TestReturnStatements.T,1)) AS N;

SELECT New_Test(
    _Language      := :'language',
    _Program       := 'evaluator_test.go:TestErrorHandling:'||N,
    _SourceCode    := TestErrorHandling.T[N][1],
    _ExpectedError := ARRAY[TestErrorHandling.T[N][2]]
) FROM (
    SELECT ARRAY[
        [
            '5 + true;',
            'type mismatch: INTEGER + BOOLEAN'
        ],
        [
            '5 + true; 5;',
            'type mismatch: INTEGER + BOOLEAN'
        ],
        [
            '-true',
            'unknown operator: -BOOLEAN'
        ],
        [
            'true + false;',
            'unknown operator: BOOLEAN + BOOLEAN'
        ],
        [
            'true + false + true + false;',
            'unknown operator: BOOLEAN + BOOLEAN'
        ],
        [
            '5; true + false; 5',
            'unknown operator: BOOLEAN + BOOLEAN'
        ],
        [
            '"Hello" - "World"',
            'unknown operator: STRING - STRING'
        ],
        [
            'if (10 > 1) { true + false; }',
            'unknown operator: BOOLEAN + BOOLEAN'
        ],
        [
            'if (10 > 1) {
               if (10 > 1) {
                 return true + false;
               }
             
               return 1;
             }',
            'unknown operator: BOOLEAN + BOOLEAN'
        ],
        [
            'foobar',
            'identifier not found: foobar'
        ],
        [
            '{"name": "Monkey"}[fn(x) { x }];',
            'unusable as hash key: FUNCTION'
        ],
        [
            '999[1]',
            'index operator not supported: INTEGER'
        ]
    ] AS T
) AS TestErrorHandling
CROSS JOIN generate_series(1,array_length(TestErrorHandling.T,1)) AS N;

SELECT New_Test(
    _Language      := :'language',
    _Program       := 'evaluator_test.go:TestLetStatements:'||N,
    _SourceCode    := TestLetStatements.T[N][1],
    _ExpectedType  := 'integer',
    _ExpectedValue := TestLetStatements.T[N][2]
) FROM (
    SELECT ARRAY[
        ['let a = 5; a;',                                '5'],
        ['let a = 5 * 5; a;',                           '25'],
        ['let a = 5; let b = a; b;',                     '5'],
        ['let a = 5; let b = a; let c = a + b + 5; c;', '15']
    ] AS T
) AS TestLetStatements
CROSS JOIN generate_series(1,array_length(TestLetStatements.T,1)) AS N;

SELECT New_Test(
    _Language      := :'language',
    _Program       := 'evaluator_test.go:TestFunctionApplication:'||N,
    _SourceCode    := TestFunctionApplication.T[N][1],
    _ExpectedType  := 'integer',
    _ExpectedValue := TestFunctionApplication.T[N][2]
) FROM (
    SELECT ARRAY[
        ['let identity = fn(x) { x; }; identity(5);',              '5'],
        ['let identity = fn(x) { return x; }; identity(5);',       '5'],
        ['let double = fn(x) { x * 2; }; double(5);',             '10'],
        ['let add = fn(x, y) { x + y; }; add(5, 5);',             '10'],
        ['let add = fn(x, y) { x + y; }; add(5 + 5, add(5, 5));', '20'],
        ['fn(x) { x; }(5)',                                        '5']
    ] AS T
) AS TestFunctionApplication
CROSS JOIN generate_series(1,array_length(TestFunctionApplication.T,1)) AS N;

SELECT New_Test(
    _Language      := :'language',
    _Program       := 'evaluator_test.go:TestEnclosingEnvironments',
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
    _ExpectedType  := 'integer',
    _ExpectedValue := '70'
);

SELECT New_Test(
    _Language      := :'language',
    _Program       := 'evaluator_test.go:TestClosures',
    _SourceCode    := $$
        let newAdder = fn(x) {
          fn(y) { x + y };
        };

        let addTwo = newAdder(2);
        addTwo(2);
    $$,
    _ExpectedType  := 'integer',
    _ExpectedValue := '4'
);

SELECT New_Test(
    _Language      := :'language',
    _Program       := 'evaluator_test.go:TestStringLiteral',
    _SourceCode    := $$"Hello World!"$$,
    _ExpectedType  := 'text'::regtype,
    _ExpectedValue := 'Hello World!'
);

SELECT New_Test(
    _Language      := :'language',
    _Program       := 'evaluator_test.go:TestStringConcatenation',
    _SourceCode    := $$"Hello" + " " + "World!"$$,
    _ExpectedType  := 'text'::regtype,
    _ExpectedValue := 'Hello World!'
);

SELECT New_Test(
    _Language      := :'language',
    _Program       := 'evaluator_test.go:TestBuiltinFunctions1:'||N,
    _SourceCode    := TestBuiltinFunctions.T[N][1],
    _ExpectedType  := TestBuiltinFunctions.T[N][2]::regtype,
    _ExpectedValue := TestBuiltinFunctions.T[N][3]
) FROM (
    SELECT ARRAY[
        ['len("")',                 'integer', '0'],
        ['len("four")',             'integer', '4'],
        ['len("hello world")',      'integer', '11'],
        ['len([1, 2, 3])',          'integer', '3'],
        ['len([])',                 'integer', '0'],
        ['puts("hello", "world!")', 'nil',     'nil'],
        ['first([1, 2, 3])',        'integer', '1'],
        ['first([])',               'nil',     'nil'],
        ['last([1, 2, 3])',         'integer', '3'],
        ['last([])',                'nil',     'nil'],
        ['rest([])',                'nil',     'nil']
    ] AS T
) AS TestBuiltinFunctions
CROSS JOIN generate_series(1,array_length(TestBuiltinFunctions.T,1)) AS N;

SELECT New_Test(
    _Language      := :'language',
    _Program       := 'evaluator_test.go:TestBuiltinFunctions2:'||N,
    _SourceCode    := TestBuiltinFunctions.T[N][1],
    _ExpectedError := ARRAY[TestBuiltinFunctions.T[N][2]]
) FROM (
    SELECT ARRAY[
        ['len(1)',            'argument to `len` not supported, got INTEGER'],
        ['len("one", "two")', 'wrong number of arguments. got=2, want=1'],
        ['first(1)',          'argument to `first` must be ARRAY, got INTEGER'],
        ['last(1)',           'argument to `last` must be ARRAY, got INTEGER'],
        ['push(1, 1)',        'argument to `push` must be ARRAY, got INTEGER']
    ] AS T
) AS TestBuiltinFunctions
CROSS JOIN generate_series(1,array_length(TestBuiltinFunctions.T,1)) AS N;

SELECT New_Test(
    _Language       := :'language',
    _Program        := 'evaluator_test.go:TestBuiltinFunctions3',
    _SourceCode     := $$rest([1, 2, 3])$$,
    _ExpectedTypes  := ARRAY['integer','integer']::regtype[],
    _ExpectedValues := ARRAY['2','3']
);

SELECT New_Test(
    _Language       := :'language',
    _Program        := 'evaluator_test.go:TestBuiltinFunctions4',
    _SourceCode     := $$push([], 1)$$,
    _ExpectedTypes  := ARRAY['integer']::regtype[],
    _ExpectedValues := ARRAY['1']
);

SELECT New_Test(
    _Language       := :'language',
    _Program        := 'evaluator_test.go:TestBuiltinFunctions5',
    _SourceCode     := $$puts("hello", "world!")$$,
    _ExpectedSTDOUT := ARRAY['hello','world!']
);

SELECT New_Test(
    _Language       := :'language',
    _Program        := 'evaluator_test.go:TestArrayLiterals',
    _SourceCode     := $$[1, 2 * 2, 3 + 3]$$,
    _ExpectedTypes  := ARRAY['integer','integer','integer']::regtype[],
    _ExpectedValues := ARRAY['1','4','6']
);

SELECT New_Test(
    _Language      := :'language',
    _Program       := 'evaluator_test.go:TestArrayIndexExpressions:'||N,
    _SourceCode    := TestArrayIndexExpressions.T[N][1],
    _ExpectedType  := TestArrayIndexExpressions.T[N][2]::regtype,
    _ExpectedValue := TestArrayIndexExpressions.T[N][3]
) FROM (
    SELECT ARRAY[
        [
            '[1, 2, 3][0]',
            'integer',
            '1'
        ],
        [
            '[1, 2, 3][1]',
            'integer',
            '2'
        ],
        [
            '[1, 2, 3][2]',
            'integer',
            '3'
        ],
        [
            'let i = 0; [1][i];',
            'integer',
            '1'
        ],
        [
            '[1, 2, 3][1 + 1];',
            'integer',
            '3'
        ],
        [
            'let myArray = [1, 2, 3]; myArray[2];',
            'integer',
            '3'
        ],
        [
            'let myArray = [1, 2, 3]; myArray[0] + myArray[1] + myArray[2];',
            'integer',
            '6'
        ],
        [
            'let myArray = [1, 2, 3]; let i = myArray[0]; myArray[i]',
            'integer',
            '2'
        ],
        [
            '[1, 2, 3][3]',
            'nil',
            'nil'
        ],
        [
            '[1, 2, 3][-1]',
            'nil',
            'nil'
        ]
    ] AS T
) AS TestArrayIndexExpressions
CROSS JOIN generate_series(1,array_length(TestArrayIndexExpressions.T,1)) AS N;

SELECT New_Test(
    _Language      := :'language',
    _Program       := 'evaluator_test.go:TestHashLiterals',
    _SourceCode    := $$
        let two = "two";
        let h = {
            "one": 10 - 9,
            two: 1 + 1,
            "thr" + "ee": 6 / 2,
            4: 4,
            true: 5,
            false: 6
        };
        [
            h["one"],
            h["two"],
            h["three"],
            h[4],
            h[true],
            h[false]
        ]
    $$,
    _ExpectedTypes  := ARRAY['integer','integer','integer','integer','integer','integer']::regtype[],
    _ExpectedValues := ARRAY['1','2','3','4','5','6']
);

SELECT New_Test(
    _Language      := :'language',
    _Program       := 'evaluator_test.go:TestHashIndexExpressions:'||N,
    _SourceCode    := TestHashIndexExpressions.T[N][1],
    _ExpectedType  := TestHashIndexExpressions.T[N][2]::regtype,
    _ExpectedValue := TestHashIndexExpressions.T[N][3]
) FROM (
    SELECT ARRAY[
        ['{"foo": 5}["foo"]',                'integer',   '5'],
        ['{"foo": 5}["bar"]',                'nil',     'nil'],
        ['let key = "foo"; {"foo": 5}[key]', 'integer',   '5'],
        ['{}["foo"]',                        'nil',     'nil'],
        ['{5: 5}[5]',                        'integer',   '5'],
        ['{true: 5}[true]',                  'integer',   '5'],
        ['{false: 5}[false]',                'integer',   '5']
    ] AS T
) AS TestHashIndexExpressions
CROSS JOIN generate_series(1,array_length(TestHashIndexExpressions.T,1)) AS N;

SELECT New_Test(
    _Language       := :'language',
    _Program        := 'Test-Driving Arrays',
    _SourceCode     := $$
        let map = fn(arr, f) {
            let iter = fn(arr, accumulated) {
                if (len(arr) == 0) {
                    accumulated
                } else {
                    iter(rest(arr), push(accumulated, f(first(arr))));
                }
            };
            iter(arr, []);
        };
        let a = [1, 2, 3, 4];
        let double = fn(x) { x * 2 };
        map(a, double)
    $$,
    _ExpectedTypes  := ARRAY['integer','integer','integer','integer']::regtype[],
    _ExpectedValues := ARRAY['2','4','6','8']::text[]
);

SELECT New_Test(
    _Language      := :'language',
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
    _Language      := :'language',
    _Program       := 'Anonymous functions',
    _SourceCode    := $$
        fn(x,y) {x*y}(1+2,3)
    $$,
    _ExpectedType  := 'integer'::regtype,
    _ExpectedValue := '9'
);

SELECT COUNT(*) FROM (
    SELECT ProgramID, Run(Language, Program)
    FROM View_Programs
    WHERE Language = :'language'
) AS Tests;
