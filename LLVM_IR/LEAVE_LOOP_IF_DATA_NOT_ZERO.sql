CREATE OR REPLACE FUNCTION "LLVM_IR"."LEAVE_LOOP_IF_DATA_NOT_ZERO"(_NodeID integer)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
BEGIN
PERFORM LLVMIR(_NodeID, '
%.6 = load i32, i32* %Ptr
%.7 = getelementptr inbounds i8, i8* %Data, i32 %.6
%.8 = load i8, i8* %.7
%.9 = icmp ne i8 %.8, 0
      br i1 %.9, label %.5, label %.10
.10:
');
RETURN;
END;
$$;
