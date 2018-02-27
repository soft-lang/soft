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
       br i1 %.4, label %.16, label %.5
.5:
%.6  = load i32, i32* %Ptr
%.7  = '||_Operator||' i32 %.6, '||ABS(_Argument)||'
%.8  = icmp sge i32 %.7, %Size
%.9  = icmp slt i32 %.7, 0
%.10 = or i1 %.8, %.9
       br i1 %.10, label %.11, label %.12
.11:
       ret i32 %NodeID
.12:
       store i32 %.7, i32* %Ptr
%.13 = getelementptr inbounds i8, i8* %Data, i32 %.7
%.14 = load i8, i8* %.13
%.15 = icmp ne i8 %.14, 0
       br i1 %.15, label %.5, label %.16
.16:
');

RETURN;
END;
$$;
