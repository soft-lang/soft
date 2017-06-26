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

_ClonedNodeID := Clone_Node(Dereference(_ParentNodes[2]));

IF (SELECT PrimitiveType FROM Nodes WHERE NodeID = Dereference(_ParentNodes[3])) IS NOT NULL THEN
    SELECT New_Node(
        _ProgramID        := ProgramID,
        _NodeTypeID       := NodeTypeID,
        _PrimitiveType    := PrimitiveType,
        _PrimitiveValue   := PrimitiveValue,
        _Walkable         := Walkable,
        _ClonedFromNodeID := NodeID,
        _ClonedRootNodeID := Dereference(_ParentNodes[3]),
        _ReferenceNodeID  := ReferenceNodeID
    ) INTO STRICT _PushNodeID
    FROM Nodes
    WHERE NodeID = Dereference(_ParentNodes[3]);
	RAISE NOTICE 'Node % is primitive, created node %', Dereference(_ParentNodes[3]), _PushNodeID;
ELSE
	_PushNodeID := Clone_Node(Dereference(_ParentNodes[3]));
END IF;

PERFORM New_Edge(
	_ProgramID    := ProgramID(_NodeID),
	_ParentNodeID := _PushNodeID,
	_ChildNodeID  := _ClonedNodeID
);

PERFORM Set_Reference_Node(_ReferenceNodeID := _ClonedNodeID, _NodeID := _NodeID);

RETURN;
END;
$$;
