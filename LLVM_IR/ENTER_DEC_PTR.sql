CREATE OR REPLACE FUNCTION "LLVM_IR"."ENTER_DEC_PTR"(_NodeID integer)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_ArgumentNodeID integer;
_Argument       integer;
BEGIN
_ArgumentNodeID := Parent(_NodeID, 'ARGUMENT');
_Argument       := COALESCE(Primitive_Value(_ArgumentNodeID)::integer, 1);

PERFORM Log(
    _NodeID   := _NodeID,
    _Severity := 'STDOUT',
    _Message  := format($IR$
; >ENTER_DEC_PTR %1$s
%%dataptr_%1$s     = load i32, i32* %%dataptr_addr
%%dec_dataptr_%1$s = sub i32 %%dataptr_%1$s, %2$s
                     store i32 %%dec_dataptr_%1$s, i32* %%dataptr_addr
; <ENTER_DEC_PTR %1$s
$IR$, _NodeID, _Argument)
);
RETURN;
END;
$$;
