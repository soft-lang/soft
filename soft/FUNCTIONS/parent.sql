CREATE OR REPLACE FUNCTION Parent(_NodeID integer, _NodeType text DEFAULT NULL)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_ParentNodeID integer;
_Count        bigint;
BEGIN
IF _NodeID IS NULL THEN
    RETURN NULL;
END IF;
SELECT  Edges.ParentNodeID,  COUNT(*) OVER ()
INTO         _ParentNodeID, _Count
FROM Edges
INNER JOIN Nodes     ON Nodes.NodeID         = Edges.ParentNodeID
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
WHERE Edges.ChildNodeID  = _NodeID
AND  (NodeTypes.NodeType = _NodeType OR _NodeType IS NULL)
AND   Edges.DeathPhaseID IS NULL
AND   Nodes.DeathPhaseID IS NULL
LIMIT 1;
IF _Count = 1 THEN
    RETURN _ParentNodeID;
END IF;
RETURN NULL;
END;
$$;
