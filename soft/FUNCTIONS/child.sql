CREATE OR REPLACE FUNCTION Child(_NodeID integer, _NodeType text DEFAULT NULL)
RETURNS integer
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
_ChildNodeID integer;
_Count       bigint;
BEGIN
IF _NodeID IS NULL THEN
    RETURN NULL;
END IF;
SELECT  Edges.ChildNodeID,  COUNT(*) OVER ()
INTO         _ChildNodeID, _Count
FROM Edges
INNER JOIN Nodes     ON Nodes.NodeID         = Edges.ChildNodeID
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
WHERE Edges.ParentNodeID  = _NodeID
AND  (NodeTypes.NodeType  = _NodeType OR _NodeType IS NULL)
AND   Edges.DeathPhaseID IS NULL
AND   Nodes.DeathPhaseID IS NULL
LIMIT 1;
IF _Count = 1 THEN
    RETURN _ChildNodeID;
END IF;
RETURN NULL;
END;
$$;
