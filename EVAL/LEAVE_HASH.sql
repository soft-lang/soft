CREATE OR REPLACE FUNCTION "EVAL"."LEAVE_HASH"(_NodeID integer) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
BEGIN
PERFORM Set_Walkable(_NodeID, FALSE);
RETURN;
END;
$$;