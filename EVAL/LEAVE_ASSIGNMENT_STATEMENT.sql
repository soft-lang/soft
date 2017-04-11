CREATE OR REPLACE FUNCTION "EVAL"."LEAVE_ASSIGNMENT_STATEMENT"(_NodeID integer) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_ParentNodes integer[];
_OK boolean;
BEGIN

SELECT array_agg(ParentNodeID ORDER BY EdgeID)
INTO STRICT _ParentNodes
FROM Edges
WHERE ChildNodeID = _NodeID
AND DeathPhaseID IS NULL;

IF array_length(_ParentNodes, 1) = 2 THEN
    PERFORM Copy_Node(_FromNodeID := _ParentNodes[2], _ToNodeID := _ParentNodes[1]);
ELSE
    RAISE EXCEPTION 'Assignment statement does not have exactly two parent nodes NodeID % ParentNodes %', _NodeID, _ParentNodes;
END IF;

RETURN;
END;
$$;
