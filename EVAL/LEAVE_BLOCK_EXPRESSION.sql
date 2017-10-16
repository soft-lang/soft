CREATE OR REPLACE FUNCTION "EVAL"."LEAVE_BLOCK_EXPRESSION"(_NodeID integer)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_LastNodeID integer;
_OK         boolean;
BEGIN

SELECT ParentNodeID
INTO    _LastNodeID
FROM Edges
WHERE ChildNodeID = _NodeID
AND DeathPhaseID IS NULL
ORDER BY EdgeID DESC
LIMIT 1;

IF NOT FOUND THEN
    -- Empty block
    RETURN;
END IF;

PERFORM Set_Reference_Node(
    _ReferenceNodeID := _LastNodeID,
    _NodeID          := _NodeID
);

RETURN;
END;
$$;
