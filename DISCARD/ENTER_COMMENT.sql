CREATE OR REPLACE FUNCTION "DISCARD"."ENTER_COMMENT"(_NodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
BEGIN
RETURN Discard_Node(_NodeID);
END;
$$;
