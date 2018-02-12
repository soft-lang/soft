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
%%stdout_size_%1$s     = load i32, i32* %%stdout_size_addr
%%stdout_addr_%1$s     = getelementptr inbounds i8, i8* %%stdout_buffer, i32 %%stdout_size_%1$s
                         store i8 %%element_%1$s, i8* %%stdout_addr_%1$s
%%inc_stdout_size_%1$s = add i32 %%stdout_size_%1$s, 1
                         store i32 %%inc_stdout_size_%1$s, i32* %%stdout_size_addr
; <ENTER_WRITE_STDOUT %1$s
$IR$, _NodeID));
RETURN;
END;
$$;
