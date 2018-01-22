CREATE OR REPLACE FUNCTION "EVAL"."ENTER_JUMP_IF_DATA_NOT_ZERO"(_NodeID integer)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
BEGIN
IF Primitive_Value(Parent(_NodeID, 'DATA')) <> '0' THEN
    PERFORM Set_Program_Node(Child(_NodeID), 'ENTER');
END IF;
RETURN;
END;
$$;