CREATE OR REPLACE FUNCTION "LLVM_IR"."ENTER_READ_STDIN"(_NodeID integer)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
BEGIN
PERFORM LLVMIR(_NodeID, '
ret i32 %NodeID
Node%NodeID:
');
RETURN;
END;
$$;
