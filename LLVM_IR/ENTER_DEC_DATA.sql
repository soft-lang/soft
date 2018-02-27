CREATE OR REPLACE FUNCTION "LLVM_IR"."ENTER_DEC_DATA"(_NodeID integer)
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
%.2 = getelementptr inbounds i8, i8* %Data, i32 %.1
%.3 = load i8, i8* %.2
%.4 = sub i8 %.3, '||_Argument||'
      store i8 %.4, i8* %.2
');
RETURN;
END;
$$;
