CREATE OR REPLACE FUNCTION "EVAL"."LEAVE_LET_STATEMENT"(_NodeID integer) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_ParentNodes  integer[];
_ClonedNodeID integer;
_OK           boolean;
BEGIN

SELECT array_agg(ParentNodeID ORDER BY EdgeID)
INTO STRICT _ParentNodes
FROM Edges
WHERE ChildNodeID = _NodeID
AND DeathPhaseID IS NULL;

IF array_length(_ParentNodes, 1) = 2 THEN
    _ClonedNodeID := Clone_Node(_NodeID := _ParentNodes[2]);
    UPDATE Edges SET ChildNodeID  = _ClonedNodeID WHERE ChildNodeID  = _ParentNodes[1] AND DeathPhaseID IS NULL;
    UPDATE Edges SET ParentNodeID = _ClonedNodeID WHERE ParentNodeID = _ParentNodes[1] AND DeathPhaseID IS NULL;
    PERFORM Kill_Clone(_ParentNodes[1]);
ELSE
    RAISE EXCEPTION 'Let statement does not have exactly two parent nodes NodeID % ParentNodes %', _NodeID, _ParentNodes;
END IF;

RETURN;
END;
$$;
