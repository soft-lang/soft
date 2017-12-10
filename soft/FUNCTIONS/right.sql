CREATE OR REPLACE FUNCTION Right(_NodeID integer)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_RightNodeID integer;
BEGIN

SELECT Edges.ParentNodeID
INTO         _RightNodeID
FROM Edges
INNER JOIN Nodes ON Nodes.NodeID = Edges.ParentNodeID
WHERE Edges.EdgeID       > Edge(_NodeID,Child(_NodeID))
AND   Edges.ChildNodeID  = Child(_NodeID)
AND   Edges.DeathPhaseID IS NULL
AND   Nodes.DeathPhaseID IS NULL
ORDER BY Edges.EdgeID ASC
LIMIT 1;

RETURN _RightNodeID;
END;
$$;
