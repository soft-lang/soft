SET search_path TO soft, public, pg_temp;

\set language lox

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
