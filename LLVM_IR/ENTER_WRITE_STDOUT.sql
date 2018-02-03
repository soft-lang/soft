CREATE OR REPLACE FUNCTION "LLVM_IR"."ENTER_WRITE_STDOUT"(_NodeID integer)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
BEGIN
PERFORM Log(
    _NodeID   := _NodeID,
    _Severity := 'STDOUT',
    _Message  := format($IR$
; >ENTER_WRITE_STDOUT %1$s
%%dataptr%1$s      = load i32, i32* %%dataptr_addr
%%element_addr%1$s = getelementptr inbounds i8, i8* %%memory, i32 %%dataptr%1$s
%%element%1$s      = load i8, i8* %%element_addr%1$s
%%element_i32_%1$s = zext i8 %%element%1$s to i32
%%call_%1$s        = call i32 @putchar(i32 %%element_i32_%1$s)
; <ENTER_WRITE_STDOUT %1$s
$IR$, _NodeID)
);
RETURN;
END;
$$;
