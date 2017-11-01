SET search_path TO soft, public, pg_temp;

\set language lox

SELECT COUNT(*) FROM (
    SELECT New_Test(
        _Language   := :'language',
        _Program    := FilePath,
        _SourceCode := FileContent
    ) FROM Get_Files(
        _Path       := 'github.com/munificent/craftinginterpreters/test',
        _FileSuffix := '\.lox$'
    )
    WHERE FilePath LIKE '%/manorboy/%'
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
