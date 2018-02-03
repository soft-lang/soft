CREATE OR REPLACE FUNCTION "LLVM_IR"."ENTER_DEC_DATA"(_NodeID integer)
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
; >ENTER_DEC_DATA %1$s
%%dataptr_%1$s      = load i32, i32* %%dataptr_addr
%%element_addr_%1$s = getelementptr inbounds i8, i8* %%memory, i32 %%dataptr_%1$s
%%element_%1$s      = load i8, i8* %%element_addr_%1$s
%%sub_element_%1$s  = sub i8 %%element_%1$s, %2$s
                      store i8 %%sub_element_%1$s, i8* %%element_addr_%1$s
; <ENTER_DEC_DATA %1$s
$IR$, _NodeID, _Argument)
);
RETURN;
END;
$$;
