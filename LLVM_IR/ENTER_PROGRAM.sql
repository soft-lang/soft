CREATE OR REPLACE FUNCTION "LLVM_IR"."ENTER_PROGRAM"(_NodeID integer)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
BEGIN
PERFORM LLVMIR(_NodeID, '
define i32 @__llvmjit(i8* %Data, i32 %Size, i32* %Ptr, i8* %STDOUTBuffer, i32* %STDOUTRemaining) {
entry:
');
RETURN;
END;
$$;
