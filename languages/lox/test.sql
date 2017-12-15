SET search_path TO soft, public, pg_temp;

\set language lox

SELECT COUNT(*) FROM (
    SELECT New_Test(
        _Language    := :'language',
        _Program     := FilePath,
        _SourceCode  := FileContent,
        _LogSeverity := 'NOTICE'
    ) FROM Get_Files(
        _Path       := 'github.com/munificent/craftinginterpreters/test',
        _FileSuffix := '\.lox$'
    )
    WHERE TRUE
--    AND   FileContent LIKE '%// expect:%'
--    AND   FileContent NOT LIKE '%// expect runtime error:%'
--    AND   FileContent NOT LIKE '%// Error%'
--    AND   FileContent NOT LIKE '%// [line %'
--    AND   FileContent NOT LIKE '%// [java line %'
  AND  (FileContent LIKE '%// expect runtime error:%'
     OR FileContent LIKE '%// expect:%')
--     OR FileContent LIKE '%// [line %'
--     OR FileContent LIKE '%// [java line %')
--    AND FileContent NOT LIKE '%// Error%'
    AND   FilePath    NOT LIKE '%/test/scanning/%'
    AND   FilePath    NOT LIKE '%/test/expressions/%'
    AND   FilePath    NOT LIKE '%/test/benchmark/%'
    AND   FilePath    !~ '/limit/(loop_too_large|too_many_constants|too_many_locals|too_many_upvalues|stack_overflow)\.lox$'
    AND   FilePath NOT IN (
            'github.com/munificent/craftinginterpreters/test/function/local_mutual_recursion.lox'
    )
) AS Tests;

-- SELECT COUNT(*) FROM (
--     SELECT ProgramID, Run(Language, Program)
--     FROM View_Programs
--     WHERE Language = :'language'
-- ) AS Tests;
