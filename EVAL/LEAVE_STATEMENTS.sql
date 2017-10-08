CREATE OR REPLACE FUNCTION "EVAL"."LEAVE_STATEMENTS"(_NodeID integer)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_LastNodeID integer;
_OK         boolean;
BEGIN

SELECT Dereference(ParentNodeID)
INTO STRICT _LastNodeID
FROM Edges
WHERE ChildNodeID = _NodeID
AND DeathPhaseID IS NULL
ORDER BY EdgeID DESC
LIMIT 1;

PERFORM Set_Reference_Node(
    _ReferenceNodeID := _LastNodeID,
    _NodeID          := _NodeID
);

RETURN;
END;
$$;
