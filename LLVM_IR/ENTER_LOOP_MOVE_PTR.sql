CREATE OR REPLACE FUNCTION "LLVM_IR"."ENTER_LOOP_MOVE_PTR"(_NodeID integer)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_ArgumentNodeID integer;
_Argument       integer;
BEGIN
_ArgumentNodeID := Parent(_NodeID, 'ARGUMENT');
_Argument       := COALESCE(Primitive_Value(_ArgumentNodeID)::integer, 1);

PERFORM LLVMIR(_NodeID, format($IR$
; >ENTER_LOOP_MOVE_PTR %1$s %3$s
%%dataptr_%1$s           = load i32, i32* %%dataptr_addr
%%element_addr_%1$s      = getelementptr inbounds i8, i8* %%memory, i32 %%dataptr_%1$s
%%element_%1$s           = load i8, i8* %%element_addr_%1$s
%%compare_zero_%1$s      = icmp eq i8 %%element_%1$s, 0
                           br i1 %%compare_zero_%1$s, label %%post_loop_%1$s, label %%loop_body_%1$s
loop_body_%1$s:
%%new_dataptr_%1$s       = load i32, i32* %%dataptr_addr
%%mov_dataptr_%1$s       = %3$s i32 %%new_dataptr_%1$s, %2$s
                           store i32 %%mov_dataptr_%1$s, i32* %%dataptr_addr
%%new_element_addr_%1$s  = getelementptr inbounds i8, i8* %%memory, i32 %%mov_dataptr_%1$s
%%new_element_%1$s       = load i8, i8* %%new_element_addr_%1$s
%%new_compare_zero_%1$s  = icmp ne i8 %%new_element_%1$s, 0
                           br i1 %%new_compare_zero_%1$s, label %%loop_body_%1$s, label %%post_loop_%1$s
post_loop_%1$s:
; <ENTER_LOOP_MOVE_PTR %1$s %3$s
$IR$, _NodeID, ABS(_Argument), CASE WHEN _Argument > 0 THEN 'add' WHEN _Argument < 0 THEN 'sub' END));
RETURN;
END;
$$;
