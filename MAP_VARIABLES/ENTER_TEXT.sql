CREATE OR REPLACE FUNCTION "MAP_VARIABLES"."ENTER_TEXT"(_NodeID integer)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
BEGIN
PERFORM Goto_Child(_NodeID);
PERFORM Set_Walkable(_NodeID, FALSE);
RETURN;
END;
$$;
