CREATE OR REPLACE FUNCTION "LLVM_IR"."ENTER_LOOP_SET_TO_ZERO"(_NodeID integer)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_ArgumentNodeID integer;
_Argument       integer;
BEGIN
PERFORM LLVMIR(_NodeID, format($IR$
; >ENTER_LOOP_SET_TO_ZERO %1$s
%%dataptr_%1$s      = load i32, i32* %%dataptr_addr
%%element_addr_%1$s = getelementptr inbounds i8, i8* %%memory, i32 %%dataptr_%1$s
                      store i8 0, i8* %%element_addr_%1$s
; <ENTER_LOOP_SET_TO_ZERO %1$s
$IR$, _NodeID));
RETURN;
END;
$$;
