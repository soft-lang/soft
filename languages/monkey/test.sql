SET search_path TO soft, public, pg_temp;

SELECT New_Test(
    _Language      := 'monkey',
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
CROSS JOIN generate_series(1,array_length(TestEvalIntegerExpression.T,1)) AS N

SELECT New_Test(
    _Language      := 'monkey',
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
CROSS JOIN generate_series(1,array_length(TestEvalBooleanExpression.T,1)) AS N

SELECT New_Test(
    _Language      := 'monkey',
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
CROSS JOIN generate_series(1,array_length(TestBangOperator.T,1)) AS N

SELECT New_Test(
    _Language      := 'monkey',
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
CROSS JOIN generate_series(1,array_length(TestIfElseExpressions.T,1)) AS N

SELECT New_Test(
    _Language      := 'monkey',
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
CROSS JOIN generate_series(1,array_length(TestReturnStatements.T,1)) AS N

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:TestErrorHandling:'||N,
    _SourceCode    := TestErrorHandling.T[N][1],
    _ExpectedError := TestErrorHandling.T[N][2]
) FROM (
    SELECT ARRAY[
        [
            '5 + true;',
            'Type mismatch: EVAL.ADD({integer,boolean})'
        ],
        [
            '5 + true; 5;',
            'Type mismatch: EVAL.ADD({integer,boolean})'
        ],
        [
            '-true',
            'operator does not exist: - boolean'
        ],
        [
            'true + false;',
            'operator does not exist: boolean + boolean'
        ],
        [
            'true + false + true + false;',
            'operator does not exist: boolean + boolean'
        ],
        [
            '5; true + false; 5',
            'operator does not exist: boolean + boolean'
        ],
        [
            '"Hello" - "World"',
            'operator does not exist: text - text'
        ],
        [
            'if (10 > 1) { true + false; }',
            'operator does not exist: boolean + boolean'
        ],
        [
            'if (10 > 1) {
               if (10 > 1) {
                 return true + false;
               }
             
               return 1;
             }',
            'operator does not exist: boolean + boolean'
        ],
        [
            '{"name": "Monkey"}[fn(x) { x }];',
            'Unusable as hash key: FUNCTION_DECLARATION'
        ],
        [
            '999[1]',
            'Index does not work with NodeType INTEGER'
        ]
    ] AS T
) AS TestErrorHandling
CROSS JOIN generate_series(1,array_length(TestErrorHandling.T,1)) AS N

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:undeclared',
    _SourceCode    := $$foobar$$,
    _ExpectedLog   := 'MAP_VARIABLES ERROR IDENTIFIER'
);

SELECT New_Test(
    _Language      := 'monkey',
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
CROSS JOIN generate_series(1,array_length(TestLetStatements.T,1)) AS N

/*

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := random()::text,
    _SourceCode    := $$let a = 5; let b = a; let c = a + b + 5; c;$$
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:169',
    _SourceCode    := $$5 + true;$$,
    _ExpectedError := 'Type mismatch: EVAL.ADD({integer,boolean})'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:173',
    _SourceCode    := $$5 + true; 5;$$,
    _ExpectedError := 'Type mismatch: EVAL.ADD({integer,boolean})'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:177',
    _SourceCode    := $$-true$$,
    _ExpectedError := 'operator does not exist: - boolean'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:181',
    _SourceCode    := $$true + false;$$,
    _ExpectedError := 'operator does not exist: boolean + boolean'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:185',
    _SourceCode    := $$true + false + true + false;$$,
    _ExpectedError := 'operator does not exist: boolean + boolean'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:189',
    _SourceCode    := $$5; true + false; 5$$,
    _ExpectedError := 'operator does not exist: boolean + boolean'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:193',
    _SourceCode    := $$"Hello" - "World"$$,
    _ExpectedError := 'operator does not exist: text - text'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:197',
    _SourceCode    := $$if (10 > 1) { true + false; }$$,
    _ExpectedError := 'operator does not exist: boolean + boolean'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:202',
    _SourceCode    := $$
        if (10 > 1) {
            if (10 > 1) {
              return true + false;
            }

            return 1;
        }
    $$,
    _ExpectedError := 'operator does not exist: boolean + boolean'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:213',
    _SourceCode    := $$foobar$$,
    _ExpectedLog   := 'MAP_VARIABLES ERROR IDENTIFIER'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:217',
    _SourceCode    := $${"name": "Monkey"}[fn(x) { x }];$$,
    _ExpectedError := 'Unusable as hash key: FUNCTION_DECLARATION'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:221',
    _SourceCode    := $$999[1]$$,
    _ExpectedError := 'Index does not work with NodeType INTEGER'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:119',
    _SourceCode    := $$return 10;$$,
    _ExpectedType  := 'integer',
    _ExpectedValue := '10'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:120',
    _SourceCode    := $$return 10; 9;$$,
    _ExpectedType  := 'integer',
    _ExpectedValue := '10'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:121',
    _SourceCode    := $$return 2 * 5; 9;$$,
    _ExpectedType  := 'integer',
    _ExpectedValue := '10'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:122',
    _SourceCode    := $$9; return 2 * 5; 9;$$,
    _ExpectedType  := 'integer',
    _ExpectedValue := '10'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:123',
    _SourceCode    := $$if (10 > 1) { return 10; }$$,
    _ExpectedType  := 'integer',
    _ExpectedValue := '10'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:124',
    _SourceCode    := $$
        if (10 > 1) {
          if (10 > 1) {
            return 10;
          }
        
          return 1;
        }
    $$,
    _ExpectedType  := 'integer',
    _ExpectedValue := '10'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:138',
    _SourceCode    := $$
        let f = fn(x) {
          return x;
          x + 10;
        };
        f(10);
    $$,
    _ExpectedType  := 'integer',
    _ExpectedValue := '10'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:147',
    _SourceCode    := $$
        let f = fn(x) {
           let result = x + 10;
           return result;
           return 10;
        };
        f(10);
    $$,
    _ExpectedType  := 'integer',
    _ExpectedValue := '20'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:75',
    _SourceCode    := $$!true$$,
    _ExpectedType  := 'boolean',
    _ExpectedValue := 'false'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:76',
    _SourceCode    := $$!false$$,
    _ExpectedType  := 'boolean',
    _ExpectedValue := 'true'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:77',
    _SourceCode    := $$!5$$,
    _ExpectedType  := 'boolean',
    _ExpectedValue := 'false'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:78',
    _SourceCode    := $$!!true$$,
    _ExpectedType  := 'boolean',
    _ExpectedValue := 'true'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:79',
    _SourceCode    := $$!!false$$,
    _ExpectedType  := 'boolean',
    _ExpectedValue := 'false'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:80',
    _SourceCode    := $$!!5$$,
    _ExpectedType  := 'boolean',
    _ExpectedValue := 'true'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:94',
    _SourceCode    := $$if (true) { 10 }$$,
    _ExpectedType  := 'integer',
    _ExpectedValue := '10'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:95',
    _SourceCode    := $$if (false) { 10 }$$,
    _ExpectedType  := 'nil',
    _ExpectedValue := 'nil'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:96',
    _SourceCode    := $$if (1) { 10 }$$,
    _ExpectedType  := 'integer',
    _ExpectedValue := '10'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:97',
    _SourceCode    := $$if (1 < 2) { 10 }$$,
    _ExpectedType  := 'integer',
    _ExpectedValue := '10'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:98',
    _SourceCode    := $$if (1 > 2) { 10 }$$,
    _ExpectedType  := 'nil',
    _ExpectedValue := 'nil'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:99',
    _SourceCode    := $$if (1 > 2) { 10 } else { 20 }$$,
    _ExpectedType  := 'integer',
    _ExpectedValue := '20'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:100',
    _SourceCode    := $$if (1 < 2) { 10 } else { 20 }$$,
    _ExpectedType  := 'integer',
    _ExpectedValue := '10'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:43',
    _SourceCode    := $$true$$,
    _ExpectedType  := 'boolean',
    _ExpectedValue := 'true'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:44',
    _SourceCode    := $$false$$,
    _ExpectedType  := 'boolean',
    _ExpectedValue := 'false'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:45',
    _SourceCode    := $$1 < 2$$,
    _ExpectedType  := 'boolean',
    _ExpectedValue := 'true'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:46',
    _SourceCode    := $$1 > 2$$,
    _ExpectedType  := 'boolean',
    _ExpectedValue := 'false'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:47',
    _SourceCode    := $$1 < 1$$,
    _ExpectedType  := 'boolean',
    _ExpectedValue := 'false'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:48',
    _SourceCode    := $$1 > 1$$,
    _ExpectedType  := 'boolean',
    _ExpectedValue := 'false'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:49',
    _SourceCode    := $$1 == 1$$,
    _ExpectedType  := 'boolean',
    _ExpectedValue := 'true'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:50',
    _SourceCode    := $$1 != 1$$,
    _ExpectedType  := 'boolean',
    _ExpectedValue := 'false'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:51',
    _SourceCode    := $$1 == 2$$,
    _ExpectedType  := 'boolean',
    _ExpectedValue := 'false'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:52',
    _SourceCode    := $$1 != 2$$,
    _ExpectedType  := 'boolean',
    _ExpectedValue := 'true'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:53',
    _SourceCode    := $$true == true$$,
    _ExpectedType  := 'boolean',
    _ExpectedValue := 'true'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:54',
    _SourceCode    := $$false == false$$,
    _ExpectedType  := 'boolean',
    _ExpectedValue := 'true'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:55',
    _SourceCode    := $$true == false$$,
    _ExpectedType  := 'boolean',
    _ExpectedValue := 'false'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:56',
    _SourceCode    := $$true != false$$,
    _ExpectedType  := 'boolean',
    _ExpectedValue := 'true'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:57',
    _SourceCode    := $$false != true$$,
    _ExpectedType  := 'boolean',
    _ExpectedValue := 'true'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:58',
    _SourceCode    := $$(1 < 2) == true$$,
    _ExpectedType  := 'boolean',
    _ExpectedValue := 'true'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:59',
    _SourceCode    := $$(1 < 2) == false$$,
    _ExpectedType  := 'boolean',
    _ExpectedValue := 'false'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:60',
    _SourceCode    := $$(1 > 2) == true$$,
    _ExpectedType  := 'boolean',
    _ExpectedValue := 'false'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:61',
    _SourceCode    := $$(1 > 2) == false$$,
    _ExpectedType  := 'boolean',
    _ExpectedValue := 'true'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:424',
    _SourceCode    := $$
        [1, 2 * 2, 3 + 3]
    $$,
    _ExpectedTypes  := ARRAY['integer','integer','integer']::regtype[],
    _ExpectedValues := ARRAY['1','4','6']
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:502',
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
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:546',
    _SourceCode    := $${"foo": 5}["foo"]$$,
    _ExpectedType  := 'integer'::regtype,
    _ExpectedValue := '5'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:550',
    _SourceCode    := $${"foo": 5}["bar"]$$,
    _ExpectedError := 'Hash key "bar" does not exist'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:554',
    _SourceCode    := $$let key = "foo"; {"foo": 5}[key]$$,
    _ExpectedType  := 'integer'::regtype,
    _ExpectedValue := '5'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:562',
    _SourceCode    := $${5: 5}[5]$$,
    _ExpectedType  := 'integer'::regtype,
    _ExpectedValue := '5'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:566',
    _SourceCode    := $${true: 5}[true]$$,
    _ExpectedType  := 'integer'::regtype,
    _ExpectedValue := '5'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:570',
    _SourceCode    := $${false: 5}[false]$$,
    _ExpectedType  := 'integer'::regtype,
    _ExpectedValue := '5'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:448',
    _SourceCode    := $$[1, 2, 3][0]$$,
    _ExpectedType  := 'integer'::regtype,
    _ExpectedValue := '1'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:452',
    _SourceCode    := $$[1, 2, 3][1]$$,
    _ExpectedType  := 'integer'::regtype,
    _ExpectedValue := '2'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:456',
    _SourceCode    := $$[1, 2, 3][2]$$,
    _ExpectedType  := 'integer'::regtype,
    _ExpectedValue := '3'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:460',
    _SourceCode    := $$let i = 0; [1][i];$$,
    _ExpectedType  := 'integer'::regtype,
    _ExpectedValue := '1'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:464',
    _SourceCode    := $$[1, 2, 3][1 + 1];$$,
    _ExpectedType  := 'integer'::regtype,
    _ExpectedValue := '3'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:468',
    _SourceCode    := $$let myArray = [1, 2, 3]; myArray[2];$$,
    _ExpectedType  := 'integer'::regtype,
    _ExpectedValue := '3'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:472',
    _SourceCode    := $$let myArray = [1, 2, 3]; myArray[0] + myArray[1] + myArray[2];$$,
    _ExpectedType  := 'integer'::regtype,
    _ExpectedValue := '6'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:476',
    _SourceCode    := $$let myArray = [1, 2, 3]; let i = myArray[0]; myArray[i]$$,
    _ExpectedType  := 'integer'::regtype,
    _ExpectedValue := '2'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:480',
    _SourceCode    := $$[1, 2, 3][3]$$,
    _ExpectedError := 'Array index 4 is out of bounds'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:484',
    _SourceCode    := $$[1, 2, 3][-1]$$,
    _ExpectedError := 'Array index 0 is out of bounds'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:368',
    _SourceCode    := $$len("one", "two")$$,
    _ExpectedError := 'Length does not have exactly one parent node'
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
        fibonacci(2);
    $$,
    _ExpectedType  := 'integer'::regtype,
    _ExpectedValue := '1'
);

SELECT New_Test(
    _Language       := 'monkey',
    _Program        := 'evaluator_test.go:380',
    _SourceCode     := $$push([], 1)$$,
    _ExpectedTypes  := ARRAY['integer']::regtype[],
    _ExpectedValues := ARRAY['1']::text[]
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:369',
    _SourceCode    := $$len([1, 2, 3])$$,
    _ExpectedType  := 'integer'::regtype,
    _ExpectedValue := '3'
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
    _ExpectedError := 'Cannot compute length of type integer'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:372',
    _SourceCode    := $$
        first([1, 2, 3])
    $$,
    _ExpectedType  := 'integer'::regtype,
    _ExpectedValue := '1'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:501',
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
        [h["one"],h["two"],h["three"],h[4],h[true],h[false]]
    $$,
    _ExpectedTypes  := ARRAY['integer','integer','integer','integer','integer','integer']::regtype[],
    _ExpectedValues := ARRAY['1','2','3','4','5','6']::text[]
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:375',
    _SourceCode    := $$
        last([1, 2, 3])
    $$,
    _ExpectedType  := 'integer'::regtype,
    _ExpectedValue := '3'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:378',
    _SourceCode    := $$
        rest([1, 2, 3])
    $$,
    _ExpectedTypes  := ARRAY['integer','integer']::regtype[],
    _ExpectedValues := ARRAY['2','3']
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
    _Program       := 'evaluator_test.go:472',
    _SourceCode    := $$
        let myArray = [1, 2, 3]; myArray[0] + myArray[1] + myArray[2];
    $$,
    _ExpectedType  := 'integer'::regtype,
    _ExpectedValue := '6'
);

SELECT New_Test(
    _Language      := 'monkey',
    _Program       := 'evaluator_test.go:476',
    _SourceCode    := $$
        let myArray = [1, 2, 3]; let i = myArray[0]; myArray[i]
    $$,
    _ExpectedType  := 'integer'::regtype,
    _ExpectedValue := '2'
);

SELECT New_Test(
    _Language       := 'monkey',
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
*/
