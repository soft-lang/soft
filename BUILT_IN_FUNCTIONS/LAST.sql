CREATE OR REPLACE FUNCTION "BUILT_IN_FUNCTIONS"."LAST"(_NodeID integer) RETURNS void
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

IF array_length(_ParentNodes, 1) IS DISTINCT FROM 2 THEN
    RAISE EXCEPTION 'last() takes exactly one array as argument';
END IF;

IF Node_Type(_ParentNodes[2]) <> 'ARRAY' THEN
	RAISE EXCEPTION 'Argument must be ARRAY, got %', Node_Type(_ParentNodes[2]);
END IF;

SELECT
	array_agg(ParentNodeID ORDER BY EdgeID)
INTO STRICT
	_ArrayElements
FROM Edges
WHERE ChildNodeID = _ParentNodes[2]
AND DeathPhaseID IS NULL;

IF _ArrayElements IS NULL THEN
	PERFORM Set_Node_Value(_NodeID, 'nil'::regtype, 'nil');
ELSE
	_ClonedNodeID := Clone_Node(_ArrayElements[array_length(_ArrayElements,1)]);
	PERFORM Set_Reference_Node(_ReferenceNodeID := _ClonedNodeID, _NodeID := _NodeID);
END IF;

RETURN;
END;
$$;
