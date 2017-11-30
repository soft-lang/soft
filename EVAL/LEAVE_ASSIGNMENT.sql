CREATE OR REPLACE FUNCTION "EVAL"."LEAVE_ASSIGNMENT"(_NodeID integer)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_ParentNodes  integer[];
_ClonedNodeID integer;
_FromNodeID   integer;
_ToNodeID     integer;
_OK           boolean;
BEGIN

SELECT array_agg(ParentNodeID ORDER BY EdgeID)
INTO STRICT _ParentNodes
FROM Edges
WHERE ChildNodeID = _NodeID
AND DeathPhaseID IS NULL;

IF array_length(_ParentNodes, 1) IS DISTINCT FROM 2 THEN
    RAISE EXCEPTION 'Assignment does not have exactly two parent nodes NodeID % ParentNodes %', _NodeID, _ParentNodes;
END IF;

_ToNodeID   := _ParentNodes[1];
_FromNodeID := Dereference(_ParentNodes[2]);

IF Node_Type(_ToNodeID) = 'GET' THEN
    _ToNodeID := Dereference(_ToNodeID);
END IF;

PERFORM Copy_Node(
    _FromNodeID := _FromNodeID,
    _ToNodeID   := _ToNodeID
);

PERFORM Set_Reference_Node(
    _ReferenceNodeID := _ToNodeID,
    _NodeID          := _NodeID
);

RETURN;
END;
$$;
