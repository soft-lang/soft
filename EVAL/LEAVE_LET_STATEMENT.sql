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

IF array_length(_ParentNodes, 1) IS DISTINCT FROM 2 THEN
    RAISE EXCEPTION 'Let statement does not have exactly two parent nodes NodeID % ParentNodes %', _NodeID, _ParentNodes;
END IF;

IF (SELECT TerminalType FROM Nodes WHERE NodeID = _ParentNodes[2]) IS NOT NULL THEN
	PERFORM Copy_Node(_FromNodeID := _ParentNodes[2], _ToNodeID := _ParentNodes[1]);
ELSE
	_ClonedNodeID := Clone_Node(_NodeID := _ParentNodes[2]);
	UPDATE Edges SET ChildNodeID  = _ClonedNodeID WHERE ChildNodeID  = _ParentNodes[1] AND DeathPhaseID IS NULL;
	UPDATE Edges SET ParentNodeID = _ClonedNodeID WHERE ParentNodeID = _ParentNodes[1] AND DeathPhaseID IS NULL;
	PERFORM Kill_Clone(_ParentNodes[1]);
END IF;

RETURN;
END;
$$;
