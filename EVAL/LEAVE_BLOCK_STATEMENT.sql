CREATE OR REPLACE FUNCTION "EVAL"."LEAVE_BLOCK_STATEMENT"(_NodeID integer)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_LastNodeID integer;
_OK         boolean;
BEGIN

IF NOT (Language(_NodeID)).StatementReturnValues THEN
    RETURN;
END IF;

PERFORM "EVAL"."LEAVE_BLOCK_EXPRESSION"(_NodeID);

RETURN;
END;
$$;
