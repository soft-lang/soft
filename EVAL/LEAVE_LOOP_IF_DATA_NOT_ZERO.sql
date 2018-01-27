CREATE OR REPLACE FUNCTION "EVAL"."LEAVE_LOOP_IF_DATA_NOT_ZERO"(_NodeID integer)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
BEGIN
IF Primitive_Value(Parent(_NodeID, 'DATA')) <> '0' THEN
    PERFORM Set_Program_Node(_NodeID, 'ENTER');
END IF;
RETURN;
END;
$$;
