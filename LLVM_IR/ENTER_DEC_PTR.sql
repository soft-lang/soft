CREATE OR REPLACE FUNCTION "LLVM_IR"."ENTER_DEC_PTR"(_NodeID integer)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_ArgumentNodeID integer;
_Argument       integer;
BEGIN
_ArgumentNodeID := Parent(_NodeID, 'ARGUMENT');
_Argument       := COALESCE(Primitive_Value(_ArgumentNodeID)::integer, 1);

PERFORM LLVMIR(_NodeID, '
%.1 = load i32, i32* %Ptr
%.2 = sub i32 %.1, '||_Argument||'
%.3 = icmp slt i32 %.2, 0
      br i1 %.3, label %.4, label %.5
.4:
      ret i32 %NodeID
.5:
      store i32 %.2, i32* %Ptr
');
RETURN;
END;
$$;
