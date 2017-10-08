CREATE OR REPLACE FUNCTION "BUILT_IN_FUNCTIONS"."PUSH"(_NodeID integer) RETURNS void
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

IF array_length(_ParentNodes, 1) IS DISTINCT FROM 3 THEN
    RAISE EXCEPTION 'push() takes exactly two arguments';
END IF;

IF Node_Type(_ParentNodes[2]) <> 'ARRAY' THEN
    RAISE EXCEPTION 'Argument must be ARRAY, got %', Node_Type(_ParentNodes[2]);
END IF;

_ClonedNodeID := Clone_Node(_ParentNodes[2]);
_PushNodeID   := Clone_Node(_ParentNodes[3]);

PERFORM New_Edge(
    _ParentNodeID := _PushNodeID,
    _ChildNodeID  := _ClonedNodeID
);

PERFORM Set_Reference_Node(_ReferenceNodeID := _ClonedNodeID, _NodeID := _NodeID);

RETURN;
END;
$$;
