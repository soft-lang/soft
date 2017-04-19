CREATE OR REPLACE FUNCTION "EVAL"."LEAVE_STATEMENTS"(_NodeID integer) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_LastNodeID integer;
BEGIN

SELECT     ParentNodeID
INTO STRICT _LastNodeID
FROM Edges
WHERE ChildNodeID = _NodeID
AND DeathPhaseID IS NULL
ORDER BY EdgeID DESC
LIMIT 1;

PERFORM Copy_Node(_FromNodeID := _LastNodeID, _ToNodeID := _NodeID);

RETURN;
END;
$$;
