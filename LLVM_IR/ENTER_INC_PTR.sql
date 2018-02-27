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

PERFORM LLVMIR(_NodeID, '
br label %Node%NodeID
Node%NodeID:
%.1 = load i32, i32* %Ptr
%.2 = add i32 %.1, '||_Argument||'
%.3 = icmp sge i32 %.2, %Size
      br i1 %.3, label %.4, label %.5
.4:
      ret i32 %NodeID
.5:
      store i32 %.2, i32* %Ptr
');
RETURN;
END;
$$;
