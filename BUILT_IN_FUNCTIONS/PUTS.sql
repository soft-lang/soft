CREATE OR REPLACE FUNCTION "BUILT_IN_FUNCTIONS"."PUTS"(_NodeID integer) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
BEGIN
-- Not implemented yet
PERFORM Set_Node_Value(_NodeID, 'nil'::regtype, 'nil');
RETURN;
END;
$$;
