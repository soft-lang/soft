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
    WHERE FileContent LIKE '%// expect:%'
    AND   FileContent NOT LIKE '%// expect runtime error:%'
    AND   FileContent NOT LIKE '%// Error%'
    AND   FileContent NOT LIKE '%// [line '
    AND   FilePath    NOT LIKE '%/test/scanning/%'
    AND   FilePath    NOT LIKE '%/test/expressions/%'
    AND   FilePath    !~ '/limit/(loop_too_large|too_many_constants|too_many_locals|too_many_upvalues|stack_overflow)\.lox$'
    AND   FilePath IN (
        'github.com/munificent/craftinginterpreters/test/class/inherited_method.lox',
        'github.com/munificent/craftinginterpreters/test/inheritance/inherit_methods.lox',
        'github.com/munificent/craftinginterpreters/test/inheritance/set_fields_from_base_class.lox',
        'github.com/munificent/craftinginterpreters/test/super/bound_method.lox',
        'github.com/munificent/craftinginterpreters/test/super/call_other_method.lox',
        'github.com/munificent/craftinginterpreters/test/super/call_same_method.lox',
        'github.com/munificent/craftinginterpreters/test/super/closure.lox',
        'github.com/munificent/craftinginterpreters/test/super/constructor.lox',
        'github.com/munificent/craftinginterpreters/test/super/indirectly_inherited.lox',
        'github.com/munificent/craftinginterpreters/test/super/reassign_superclass.lox',
        'github.com/munificent/craftinginterpreters/test/super/super_in_closure_in_inherited_method.lox',
        'github.com/munificent/craftinginterpreters/test/super/super_in_inherited_method.lox',
        'github.com/munificent/craftinginterpreters/test/super/this_in_superclass_method.lox'
    )
) AS Tests;

SELECT COUNT(*) FROM (
    SELECT ProgramID, Run(Language, Program)
    FROM View_Programs
    WHERE Language = :'language'
) AS Tests;
