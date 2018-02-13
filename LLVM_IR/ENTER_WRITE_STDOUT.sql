CREATE OR REPLACE FUNCTION "LLVM_IR"."ENTER_WRITE_STDOUT"(_NodeID integer)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
BEGIN
PERFORM LLVMIR(_NodeID, format($IR$
; >ENTER_WRITE_STDOUT %1$s
%%dataptr_%1$s         = load i32, i32* %%dataptr_addr
%%element_addr_%1$s    = getelementptr inbounds i8, i8* %%memory, i32 %%dataptr_%1$s
%%element_%1$s         = load i8, i8* %%element_addr_%1$s
%%stdout_pos_%1$s      = load i32, i32* %%stdout_pos
%%new_stdout_pos_%1$s  = sub i32 %%stdout_pos_%1$s, 1
%%stdout_addr_%1$s     = getelementptr inbounds i8, i8* %%stdout_buffer, i32 %%new_stdout_pos_%1$s
                         store i8 %%element_%1$s, i8* %%stdout_addr_%1$s
                         store i32 %%new_stdout_pos_%1$s, i32* %%stdout_pos
%%compare_zero_%1$s    = icmp eq i32 %%new_stdout_pos_%1$s, 0
                         br i1 %%compare_zero_%1$s, label %%ret_%1$s, label %%buffer_not_full_%1$s
ret_%1$s:
                         ret i32 %1$s
buffer_not_full_%1$s:
%%compare_newline_%1$s = icmp eq i8 %%element_%1$s, 10
                         br i1 %%compare_newline_%1$s, label %%ret_%1$s, label %%post_%1$s
post_%1$s:
; <ENTER_WRITE_STDOUT %1$s
$IR$, _NodeID));
RETURN;
END;
$$;
