CREATE OR REPLACE FUNCTION "LLVM_IR"."ENTER_LOOP_IF_DATA_NOT_ZERO"(_NodeID integer)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
BEGIN
PERFORM Log(
    _NodeID   := _NodeID,
    _Severity := 'STDOUT',
    _Message  := format($IR$
; >ENTER_LOOP_IF_DATA_NOT_ZERO %1$s
%%dataptr_enter_%1$s      = load i32, i32* %%dataptr_addr
%%element_addr_enter_%1$s = getelementptr inbounds i8, i8* %%memory, i32 %%dataptr_enter_%1$s
%%element_enter_%1$s      = load i8, i8* %%element_addr_enter_%1$s
%%compare_zero_enter_%1$s = icmp eq i8 %%element_enter_%1$s, 0
                            br i1 %%compare_zero_enter_%1$s, label %%post_loop_%1$s, label %%loop_body_%1$s
loop_body_%1$s:
; <ENTER_LOOP_IF_DATA_NOT_ZERO %1$s
$IR$, _NodeID)
);
RETURN;
END;
$$;
