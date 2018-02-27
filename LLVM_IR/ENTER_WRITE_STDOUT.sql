CREATE OR REPLACE FUNCTION "LLVM_IR"."ENTER_WRITE_STDOUT"(_NodeID integer)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
BEGIN
PERFORM LLVMIR(_NodeID, '
%.1  = load i32, i32* %Ptr
%.2  = getelementptr inbounds i8, i8* %Data, i32 %.1
%.3  = load i8, i8* %.2
%.4  = load i32, i32* %STDOUTRemaining
%.5  = sub i32 %.4, 1
%.6  = getelementptr inbounds i8, i8* %STDOUTBuffer, i32 %.5
       store i8 %.3, i8* %.6
       store i32 %.5, i32* %STDOUTRemaining
%.7  = icmp eq i32 %.5, 0
       br i1 %.7, label %.8, label %.9
.8:
       ret i32 %NodeID
.9:
%.10 = icmp eq i8 %.3, 10
       br i1 %.10, label %.8, label %Node%NodeID
Node%NodeID:
');
RETURN;
END;
$$;
