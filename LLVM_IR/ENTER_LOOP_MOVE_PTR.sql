CREATE OR REPLACE FUNCTION "LLVM_IR"."ENTER_LOOP_MOVE_PTR"(_NodeID integer)
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
       br i1 %.4, label %.14, label %.5
.5:
%.6  = load i32, i32* %Ptr
%.7  = '||_Operator||' i32 %.6, '||ABS(_Argument)||'
%.8  = icmp sge i32 %.7, %Size
       br i1 %.8, label %.9, label %.10
.9:
       ret i32 %NodeID
.10:
       store i32 %.7, i32* %Ptr
%.11 = getelementptr inbounds i8, i8* %Data, i32 %.7
%.12 = load i8, i8* %.11
%.13 = icmp ne i8 %.12, 0
       br i1 %.13, label %.5, label %.14
.14:
');

RETURN;
END;
$$;
