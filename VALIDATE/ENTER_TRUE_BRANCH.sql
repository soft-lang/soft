CREATE OR REPLACE FUNCTION "VALIDATE"."ENTER_TRUE_BRANCH"(_NodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
BEGIN
RETURN "VALIDATE"."ENTER_FOR_BODY"(_NodeID);
END;
$$;
