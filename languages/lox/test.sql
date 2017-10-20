SET search_path TO soft, public, pg_temp;

\set language lox

SELECT * FROM lox($$
var f1;
var f2;
var f3;

for (var i = 1; i < 4; i = i + 1) {
  var j = i;
  fun f() { print j; }

  if (j == 1) f1 = f;
  else if (j == 2) f2 = f;
  else f3 = f;
}

f1(); // expect: 1
f2(); // expect: 2
f3(); // expect: 3
$$, 'DEBUG5');

/*

SELECT Run_Test(:'language', 'fibonacci');

SELECT COUNT(*) FROM (
    SELECT New_Test(
        _Language   := :'language',
        _Program    := FilePath,
        _SourceCode := FileContent
    ) FROM Get_Files(
        _Path       := 'github.com/munificent/craftinginterpreters/test',
        _FileSuffix := '\.lox$'
    )
    WHERE FilePath LIKE '%/for/%'
) AS Tests;

SELECT COUNT(*) FROM (
    SELECT Run(Language, Program, _RunUntilPhase := 'DISCARD')
    FROM View_Programs
    WHERE Language = :'language'
    ORDER BY ProgramID
    LIMIT 10
) AS Tests;

UPDATE Tests SET
    ExpectedSTDOUT = T.ExpectedSTDOUT
FROM (
    SELECT
        ProgramID,
        array_agg(PrimitiveValue ORDER BY NodeID) AS ExpectedSTDOUT
    FROM View_Nodes
    WHERE Language   = :'language'
    AND   NodeType   = 'TEST_OUTPUT_EXPECT'
    AND   BirthPhase = 'TOKENIZE'
    AND   DeathPhase IS NULL
    GROUP BY ProgramID
) AS T
WHERE T.ProgramID = Tests.ProgramID;

*/