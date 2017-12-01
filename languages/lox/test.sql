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
    WHERE FilePath IN (
        'github.com/munificent/craftinginterpreters/test/class/simple.lox',
        'github.com/munificent/craftinginterpreters/test/assignment/associativity.lox',
        'github.com/munificent/craftinginterpreters/test/assignment/global.lox',
        'github.com/munificent/craftinginterpreters/test/assignment/local.lox',
        'github.com/munificent/craftinginterpreters/test/assignment/syntax.lox',
        'github.com/munificent/craftinginterpreters/test/block/empty.lox',
        'github.com/munificent/craftinginterpreters/test/block/scope.lox',
        'github.com/munificent/craftinginterpreters/test/bool/equality.lox',
        'github.com/munificent/craftinginterpreters/test/bool/not.lox',
        'github.com/munificent/craftinginterpreters/test/closure/assign_to_closure.lox',
        'github.com/munificent/craftinginterpreters/test/closure/assign_to_shadowed_later.lox',
        'github.com/munificent/craftinginterpreters/test/closure/close_over_function_parameter.lox',
        'github.com/munificent/craftinginterpreters/test/closure/close_over_later_variable.lox',
        'github.com/munificent/craftinginterpreters/test/closure/closed_closure_in_function.lox',
        'github.com/munificent/craftinginterpreters/test/closure/nested_closure.lox',
        'github.com/munificent/craftinginterpreters/test/closure/open_closure_in_function.lox',
        'github.com/munificent/craftinginterpreters/test/closure/reference_closure_multiple_times.lox',
        'github.com/munificent/craftinginterpreters/test/closure/reuse_closure_slot.lox',
        'github.com/munificent/craftinginterpreters/test/closure/shadow_closure_with_local.lox',
        'github.com/munificent/craftinginterpreters/test/closure/unused_closure.lox',
        'github.com/munificent/craftinginterpreters/test/comments/line_at_eof.lox',
        'github.com/munificent/craftinginterpreters/test/comments/unicode.lox',
        'github.com/munificent/craftinginterpreters/test/for/return_closure.lox',
        'github.com/munificent/craftinginterpreters/test/for/return_inside.lox',
        'github.com/munificent/craftinginterpreters/test/for/scope.lox',
        'github.com/munificent/craftinginterpreters/test/for/syntax.lox',
        'github.com/munificent/craftinginterpreters/test/function/local_recursion.lox',
        'github.com/munificent/craftinginterpreters/test/function/recursion.lox',
        'github.com/munificent/craftinginterpreters/test/if/dangling_else.lox',
        'github.com/munificent/craftinginterpreters/test/if/else.lox',
        'github.com/munificent/craftinginterpreters/test/if/if.lox',
        'github.com/munificent/craftinginterpreters/test/if/truth.lox',
        'github.com/munificent/craftinginterpreters/test/limit/reuse_constants.lox',
        'github.com/munificent/craftinginterpreters/test/logical_operator/and.lox',
        'github.com/munificent/craftinginterpreters/test/logical_operator/and_truth.lox',
        'github.com/munificent/craftinginterpreters/test/logical_operator/or.lox',
        'github.com/munificent/craftinginterpreters/test/logical_operator/or_truth.lox',
        'github.com/munificent/craftinginterpreters/test/nil/literal.lox',
        'github.com/munificent/craftinginterpreters/test/operator/add.lox',
        'github.com/munificent/craftinginterpreters/test/operator/comparison.lox',
        'github.com/munificent/craftinginterpreters/test/operator/equals.lox',
        'github.com/munificent/craftinginterpreters/test/operator/negate.lox',
        'github.com/munificent/craftinginterpreters/test/operator/not_equals.lox',
        'github.com/munificent/craftinginterpreters/test/return/after_else.lox',
        'github.com/munificent/craftinginterpreters/test/return/after_if.lox',
        'github.com/munificent/craftinginterpreters/test/return/after_while.lox',
        'github.com/munificent/craftinginterpreters/test/return/in_function.lox',
        'github.com/munificent/craftinginterpreters/test/string/literals.lox',
        'github.com/munificent/craftinginterpreters/test/variable/early_bound.lox',
        'github.com/munificent/craftinginterpreters/test/variable/in_middle_of_block.lox',
        'github.com/munificent/craftinginterpreters/test/variable/in_nested_block.lox',
        'github.com/munificent/craftinginterpreters/test/variable/scope_reuse_in_different_blocks.lox',
        'github.com/munificent/craftinginterpreters/test/variable/shadow_and_local.lox',
        'github.com/munificent/craftinginterpreters/test/variable/shadow_global.lox',
        'github.com/munificent/craftinginterpreters/test/variable/shadow_local.lox',
        'github.com/munificent/craftinginterpreters/test/while/return_closure.lox',
        'github.com/munificent/craftinginterpreters/test/while/return_inside.lox',
        'github.com/munificent/craftinginterpreters/test/while/syntax.lox'
*/
    )
) AS Tests;

SELECT COUNT(*) FROM (
    SELECT Run(Language, Program)
    FROM View_Programs
    WHERE Language = :'language'
    ORDER BY ProgramID
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
