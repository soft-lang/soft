CREATE OR REPLACE FUNCTION "LLVM_IR"."ENTER_LOOP_MOVE_DATA"(_NodeID integer)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_ArgumentNodeID integer;
_Argument       integer;
_Operator       text;
BEGIN
_ArgumentNodeID := Parent(_NodeID, 'ARGUMENT');
_Argument       := COALESCE(Primitive_Value(_ArgumentNodeID)::integer, 1);

IF _Argument > 0 THEN
    _Operator := 'add';
ELSIF _Argument < 0 THEN
    _Operator := 'sub';
ELSE
    RAISE EXCEPTION 'Unexpected Argument %', _Argument;
END IF;

PERFORM LLVMIR(_NodeID, '
br label %Node%NodeID
Node%NodeID:
%.1  = load i32, i32* %Ptr
%.2  = getelementptr inbounds i8, i8* %Data, i32 %.1
%.3  = load i8, i8* %.2
%.4  = icmp eq i8 %.3, 0
       br i1 %.4, label %.13, label %.5
.5:
%.6  = '||_Operator||' i32 %.1, '||ABS(_Argument)||'
%.7  = icmp sge i32 %.6, %Size
       br i1 %.7, label %.8, label %.9
.8:
       ret i32 %NodeID
.9:
%.10 = getelementptr inbounds i8, i8* %Data, i32 %.6
%.11 = load i8, i8* %.10
%.12 = add i8 %.11, %.3
       store i8 %.12, i8* %.10
       store i8 0, i8* %.2
       br label %.13
.13:
');
RETURN;
END;
$$;
