CREATE OR REPLACE FUNCTION "EVAL"."LEAVE_LOOP_EXPRESSION"(_NodeID integer) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
BEGIN
PERFORM Toggle_Visited(_NodeID);
PERFORM Goto_Parent(_NodeID);
RETURN;
END;
$$;
