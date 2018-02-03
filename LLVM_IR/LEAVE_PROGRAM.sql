CREATE OR REPLACE FUNCTION "LLVM_IR"."LEAVE_PROGRAM"(_NodeID integer)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
BEGIN
PERFORM Log(
    _NodeID   := _NodeID,
    _Severity := 'STDOUT',
    _Message  := format(
        $IR$
; >LEAVE_PROGRAM %1$s
ret void
}
; Function Attrs: argmemonly nounwind
declare void @llvm.memset.p0i8.i64(i8* nocapture writeonly, i8, i64, i32, i1) #0
attributes #0 = { argmemonly nounwind }
; <LEAVE_PROGRAM %1$s
$IR$, _NodeID)
);
RETURN;
END;
$$;
