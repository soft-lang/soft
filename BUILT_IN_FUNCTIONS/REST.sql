CREATE OR REPLACE FUNCTION "BUILT_IN_FUNCTIONS"."REST"(_NodeID integer) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_ParentNodes       integer[];
_ParentNodeID      integer;
_ArrayElements     integer[];
_ArrayElementEdges integer[];
_ClonedNodeID      integer;
_OK                boolean;
BEGIN

SELECT array_agg(ParentNodeID ORDER BY EdgeID)
INTO STRICT _ParentNodes
FROM Edges
WHERE ChildNodeID = _NodeID
AND DeathPhaseID IS NULL;

IF array_length(_ParentNodes, 1) IS DISTINCT FROM 2 THEN
    RAISE EXCEPTION 'rest() takes exactly one array as argument';
END IF;

_ParentNodeID := Dereference(_ParentNodes[2]);

IF Node_Type(_ParentNodeID) <> 'ARRAY' THEN
    RAISE EXCEPTION 'Argument must be ARRAY, got %', Node_Type(_ParentNodeID);
END IF;

_ClonedNodeID := Clone_Node(_ParentNodeID);

SELECT
    array_agg(ParentNodeID ORDER BY EdgeID),
    array_agg(EdgeID       ORDER BY EdgeID)
INTO STRICT
    _ArrayElements,
    _ArrayElementEdges
FROM Edges
WHERE ChildNodeID = _ClonedNodeID
AND DeathPhaseID IS NULL;

IF _ArrayElements IS NULL THEN
    PERFORM Set_Node_Value(_NodeID, 'nil'::regtype, 'nil');
ELSE
    IF array_length(_ArrayElements,1) >= 1 THEN
        PERFORM Kill_Edge(_ArrayElementEdges[1]);
        PERFORM Kill_Node(_ArrayElements[1]);
    END IF;
    PERFORM Set_Reference_Node(_ReferenceNodeID := _ClonedNodeID, _NodeID := _NodeID);
END IF;

RETURN;
END;
$$;
