CREATE OR REPLACE FUNCTION "EVAL"."LEAVE_BLOCK_STATEMENT"(_NodeID integer) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_LastNodeID integer;
_OK         boolean;
BEGIN

IF (Language(_NodeID)).StatementReturnValues THEN
    SELECT     ParentNodeID
    INTO STRICT _LastNodeID
    FROM Edges
    WHERE ChildNodeID = _NodeID
    AND DeathPhaseID IS NULL
    ORDER BY EdgeID DESC
    LIMIT 1;
	PERFORM Set_Reference_Node(_ReferenceNodeID := _LastNodeID, _NodeID := _NodeID);
END IF;

RETURN;
END;
$$;
