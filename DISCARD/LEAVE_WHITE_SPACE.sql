CREATE OR REPLACE FUNCTION "DISCARD"."LEAVE_WHITE_SPACE"(_NodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
BEGIN
PERFORM Next_Node(_NodeID);
RETURN Discard_Node(_NodeID);
END;
$$;
