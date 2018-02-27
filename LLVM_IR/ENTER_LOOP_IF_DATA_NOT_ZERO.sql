CREATE OR REPLACE FUNCTION "LLVM_IR"."ENTER_LOOP_IF_DATA_NOT_ZERO"(_NodeID integer)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
BEGIN
PERFORM LLVMIR(_NodeID, '
%.1 = load i32, i32* %Ptr
%.2 = getelementptr inbounds i8, i8* %Data, i32 %.1
%.3 = load i8, i8* %.2
%.4 = icmp eq i8 %.3, 0
      br i1 %.4, label %.10, label %.5
.5:
');
RETURN;
END;
$$;
