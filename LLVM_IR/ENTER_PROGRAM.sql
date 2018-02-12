CREATE OR REPLACE FUNCTION "LLVM_IR"."ENTER_PROGRAM"(_NodeID integer)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
BEGIN
PERFORM LLVMIR(_NodeID, format($IR$
; >ENTER_PROGRAM %1$s
define i32 @__llvmjit(i8* %%memory, i32* %%dataptr_addr) {
entry:
;ENTRY
; <ENTER_PROGRAM %1$s
$IR$, _NodeID));
RETURN;
END;
$$;
