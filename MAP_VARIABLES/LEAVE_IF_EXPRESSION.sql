CREATE OR REPLACE FUNCTION "MAP_VARIABLES"."LEAVE_IF_EXPRESSION"(_NodeID integer) RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
BEGIN
RETURN "MAP_VARIABLES"."LEAVE_IF_STATEMENT"(_NodeID);
END;
$$;
