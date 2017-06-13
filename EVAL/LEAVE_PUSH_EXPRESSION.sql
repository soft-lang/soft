CREATE OR REPLACE FUNCTION "EVAL"."LEAVE_PUSH_EXPRESSION"(_NodeID integer) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_ParentNodes       integer[];
_ArrayElements     integer[];
_ArrayElementEdges integer[];
_ClonedNodeID      integer;
_PushNodeID        integer;
_OK                boolean;
BEGIN

SELECT array_agg(ParentNodeID ORDER BY EdgeID)
INTO STRICT _ParentNodes
FROM Edges
WHERE ChildNodeID = _NodeID
AND DeathPhaseID IS NULL;

IF array_length(_ParentNodes, 1) IS DISTINCT FROM 2 THEN
    RAISE EXCEPTION 'push() takes exactly two arguments';
END IF;

_ClonedNodeID := Clone_Node(_ParentNodes[1]);
_PushNodeID   := Clone_Node(_ParentNodes[2]);

PERFORM New_Edge(
	_ProgramID    := ProgramID(_NodeID),
	_ParentNodeID := _PushNodeID,
	_ChildNodeID  := _ClonedNodeID
);

PERFORM Set_Reference_Node(_ReferenceNodeID := _ClonedNodeID, _NodeID := _NodeID);

RETURN;
END;
$$;
