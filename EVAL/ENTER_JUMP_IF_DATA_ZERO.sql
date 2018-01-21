CREATE OR REPLACE FUNCTION "EVAL"."ENTER_JUMP_IF_DATA_ZERO"(_NodeID integer)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
BEGIN
IF Primitive_Value(Heap_Integer_Array(_NodeID)) = '0' THEN
    PERFORM Set_Program_Node(Child(_NodeID), 'LEAVE');
END IF;
RETURN;
END;
$$;
