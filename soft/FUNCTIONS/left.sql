CREATE OR REPLACE FUNCTION Left(_NodeID integer)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_LeftNodeID integer;
_Count       bigint;
_ChildNodeID integer;
BEGIN

SELECT Edges.ParentNodeID
INTO          _LeftNodeID
FROM Edges
INNER JOIN Nodes ON Nodes.NodeID = Edges.ParentNodeID
WHERE Edges.EdgeID       < Edge(_NodeID,Child(_NodeID))
AND   Edges.ChildNodeID  = Child(_NodeID)
AND   Edges.DeathPhaseID IS NULL
AND   Nodes.DeathPhaseID IS NULL
ORDER BY Edges.EdgeID DESC
LIMIT 1;

RETURN _LeftNodeID;
END;
$$;
