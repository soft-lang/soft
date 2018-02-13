SET search_path TO soft, public, pg_temp;

\set language brainfuck

SELECT COUNT(*) FROM (
    SELECT New_Test(
        _Language    := :'language',
        _Program     := FilePath,
        _SourceCode  := FileContent,
        _LogSeverity := 'NOTICE'
    ) FROM Get_Files(
        _Path       := 'github.com/eliben/code-for-blog/2017/bfjit/tests/testcases',
        _FileSuffix := '\.bf$'
    )
    WHERE TRUE
    AND   FilePath ~ 'mandelbrot'
) AS Tests;

-- SELECT COUNT(*) FROM (
--     SELECT ProgramID, Run(Language, Program)
--     FROM View_Programs
--     WHERE Language = :'language'
-- ) AS Tests;
