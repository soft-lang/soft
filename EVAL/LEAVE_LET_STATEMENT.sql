CREATE OR REPLACE FUNCTION "EVAL"."LEAVE_LET_STATEMENT"(_NodeID integer)
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
    RAISE EXCEPTION 'Let statement does not have exactly two parent nodes NodeID % ParentNodes %', _NodeID, _ParentNodes;
END IF;

_ToNodeID   := _ParentNodes[1];
_FromNodeID := Dereference(_ParentNodes[2]);

IF (SELECT ClonedFromNodeID = _FromNodeID FROM Nodes WHERE NodeID = _ToNodeID) THEN
    -- Already declared from previous execution of program
ELSE
    PERFORM Copy_Node(_FromNodeID := Dereference(_ParentNodes[2]), _ToNodeID := _ParentNodes[1]);
END IF;

RETURN;
END;
$$;
