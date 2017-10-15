SET search_path TO soft, public, pg_temp;

\set language lox

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
