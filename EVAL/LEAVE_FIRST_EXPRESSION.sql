CREATE OR REPLACE FUNCTION "EVAL"."LEAVE_FIRST_EXPRESSION"(_NodeID integer) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_ParentNodes       integer[];
_ArrayElements     integer[];
_ClonedNodeID      integer;
_OK                boolean;
BEGIN

SELECT array_agg(ParentNodeID ORDER BY EdgeID)
INTO STRICT _ParentNodes
FROM Edges
WHERE ChildNodeID = _NodeID
AND DeathPhaseID IS NULL;

IF array_length(_ParentNodes, 1) IS DISTINCT FROM 1 THEN
    RAISE EXCEPTION 'first() takes exactly one array as argument';
END IF;

SELECT
    array_agg(ParentNodeID ORDER BY EdgeID)
INTO STRICT
    _ArrayElements
FROM Edges
WHERE ChildNodeID = _ParentNodes[1]
AND DeathPhaseID IS NULL;

_ClonedNodeID := Clone_Node(_ArrayElements[1]);

PERFORM Set_Reference_Node(_ReferenceNodeID := _ClonedNodeID, _NodeID := _NodeID);

RETURN;
END;
$$;
