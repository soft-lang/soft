CREATE OR REPLACE FUNCTION "MAP_VARIABLES"."LEAVE_CLASS_DECLARATION"(_NodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
BEGIN
PERFORM Set_Walkable(_NodeID, FALSE);
RETURN TRUE;
END;
$$;
