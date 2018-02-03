CREATE OR REPLACE FUNCTION "LLVM_IR"."ENTER_PROGRAM"(_NodeID integer)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
BEGIN
PERFORM Log(
    _NodeID   := _NodeID,
    _Severity := 'STDOUT',
    _Message  := format($IR$
; >ENTER_PROGRAM %1$s
; ModuleID = 'ModuleID%1$s'
source_filename = "ModuleID%1$s"
declare i32 @putchar(i32)
declare i32 @getchar()
define void @main() {
entry:
%%memory       = alloca i8, i32 30000
                 call void @llvm.memset.p0i8.i64(i8* %%memory, i8 0, i64 30000, i32 1, i1 false)
%%dataptr_addr = alloca i32
                 store  i32 0, i32* %%dataptr_addr
; <ENTER_PROGRAM %1$s
$IR$, _NodeID)
);
RETURN;
END;
$$;
