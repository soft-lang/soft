CREATE OR REPLACE FUNCTION "LLVM_IR"."ENTER_LOOP_SET_TO_ZERO"(_NodeID integer)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_ArgumentNodeID integer;
_Argument       integer;
BEGIN
PERFORM LLVMIR(_NodeID, '
%.1 = load i32, i32* %Ptr
%.2 = getelementptr inbounds i8, i8* %Data, i32 %.1
      store i8 0, i8* %.2
');
RETURN;
END;
$$;
