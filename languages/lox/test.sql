SET search_path TO soft, public, pg_temp;

\set language lox

SELECT COUNT(*) FROM (
    SELECT New_Test(
        _Language    := :'language',
        _Program     := FilePath,
        _SourceCode  := FileContent,
        _LogSeverity := 'DEBUG5'
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
--        'github.com/munificent/craftinginterpreters/test/closure/assign_to_closure.lox',
        'github.com/munificent/craftinginterpreters/test/for/closure_in_body.lox',
--        'github.com/munificent/craftinginterpreters/test/joel/scope.lox',
--        'github.com/munificent/craftinginterpreters/test/for/closure_in_body.lox',
--        'github.com/munificent/craftinginterpreters/test/closure/assign_to_closure.lox',
--        'github.com/munificent/craftinginterpreters/test/operator/equals_class.lox',
--        'github.com/munificent/craftinginterpreters/test/regression/40.lox',
--        'github.com/munificent/craftinginterpreters/test/string/multiline.lox',
--        'github.com/munificent/craftinginterpreters/test/this/closure.lox',
--        'github.com/munificent/craftinginterpreters/test/this/nested_class.lox',
--        'github.com/munificent/craftinginterpreters/test/this/nested_closure.lox',
--        'github.com/munificent/craftinginterpreters/test/variable/unreached_undefined.lox',
        ''
    )
    AND   FilePath NOT IN (
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

--    AND   FilePath IN (
--'github.com/munificent/craftinginterpreters/test/joel/return_class_vs_this.lox',
-- Currently failing tests:,
-- 'github.com/munificent/craftinginterpreters/test/closure/assign_to_closure.lox',
-- 'github.com/munificent/craftinginterpreters/test/number/literals.lox',
--'github.com/munificent/craftinginterpreters/test/operator/divide.lox',
-- 'github.com/munificent/craftinginterpreters/test/operator/equals_class.lox',
-- 'github.com/munificent/craftinginterpreters/test/operator/not.lox',
-- 'github.com/munificent/craftinginterpreters/test/operator/not_class.lox',
-- 'github.com/munificent/craftinginterpreters/test/operator/subtract.lox',
-- 'github.com/munificent/craftinginterpreters/test/precedence.lox',
-- 'github.com/munificent/craftinginterpreters/test/regression/40.lox',
-- 'github.com/munificent/craftinginterpreters/test/string/multiline.lox',
-- 'github.com/munificent/craftinginterpreters/test/this/closure.lox',
-- 'github.com/munificent/craftinginterpreters/test/this/nested_class.lox',
-- 'github.com/munificent/craftinginterpreters/test/this/nested_closure.lox',
-- 'github.com/munificent/craftinginterpreters/test/variable/unreached_undefined.lox',
--'')
/*
    WHERE FilePath IN (
        'github.com/munificent/craftinginterpreters/test/class/simple.lox'
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
    )
*/
) AS Tests;

SELECT COUNT(*) FROM (
    SELECT ProgramID, Run(Language, Program)
    FROM View_Programs
    WHERE Language = :'language'
) AS Tests;
