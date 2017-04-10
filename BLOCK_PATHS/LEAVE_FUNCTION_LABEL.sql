CREATE OR REPLACE FUNCTION "BLOCK_PATHS"."LEAVE_FUNCTION_LABEL"(_NodeID integer) RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_OK boolean;
BEGIN
UPDATE Nodes SET Walkable = FALSE WHERE NodeID = _NodeID RETURNING TRUE INTO STRICT _OK;
RETURN TRUE;
END;
$$;