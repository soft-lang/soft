CREATE OR REPLACE FUNCTION "LLVM_IR"."ENTER_INC_PTR"(_NodeID integer)
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
; >ENTER_INC_PTR %1$s
%%dataptr_%1$s     = load i32, i32* %%dataptr_addr
%%inc_dataptr_%1$s = add i32 %%dataptr_%1$s, %2$s
                     store i32 %%inc_dataptr_%1$s, i32* %%dataptr_addr
; <ENTER_INC_PTR %1$s
$IR$, _NodeID, _Argument));
RETURN;
END;
$$;
