CREATE OR REPLACE FUNCTION "EVAL"."LEAVE_IF_EXPR"(_NodeID integer) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
BEGIN
PERFORM "EVAL"."LEAVE_IF_STATEMENT"(_NodeID := _NodeID, _IfExpression := TRUE);
RETURN;
END;
$$;
