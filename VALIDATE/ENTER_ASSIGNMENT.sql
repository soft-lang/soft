CREATE OR REPLACE FUNCTION "VALIDATE"."ENTER_ASSIGNMENT"(_NodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
BEGIN
IF Find_Node(_NodeID := _NodeID, _Descend := FALSE, _Strict := FALSE, _Path := '1<- VALUE <- IDENTIFIER') IS NULL THEN
    PERFORM Log(
        _NodeID   := _NodeID,
        _Severity := 'ERROR',
        _Message  := 'Invalid assignment target.'
    );
    RETURN FALSE;
END IF;

RETURN TRUE;
END;
$$;
