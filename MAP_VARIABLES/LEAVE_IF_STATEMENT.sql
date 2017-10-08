CREATE OR REPLACE FUNCTION "MAP_VARIABLES"."LEAVE_IF_STATEMENT"(_NodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_ParentNodes integer[];
_OK boolean;
BEGIN

SELECT array_agg(Edges.ParentNodeID ORDER BY EdgeID)
INTO STRICT _ParentNodes
FROM Edges
INNER JOIN Nodes AS ParentNode ON ParentNode.NodeID = Edges.ParentNodeID
INNER JOIN Nodes AS ChildNode  ON ChildNode.NodeID  = Edges.ChildNodeID
WHERE Edges.ChildNodeID      = _NodeID
AND   Edges.DeathPhaseID      IS NULL
AND   ParentNode.DeathPhaseID IS NULL
AND   ChildNode.DeathPhaseID  IS NULL;

PERFORM Set_Walkable(_ParentNodes[2], FALSE);

IF _ParentNodes[3] IS NOT NULL THEN
    PERFORM Set_Walkable(_ParentNodes[3], FALSE);
END IF;

RETURN TRUE;
END;
$$;
