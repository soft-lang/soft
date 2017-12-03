CREATE OR REPLACE FUNCTION Count_Parents(_NodeID integer)
RETURNS bigint
LANGUAGE plpgsql
AS $$
DECLARE
_Count bigint;
BEGIN
SELECT COUNT(*)
INTO  _Count
FROM Edges
INNER JOIN Nodes ON Nodes.NodeID = Edges.ParentNodeID
WHERE Edges.ChildNodeID  = _NodeID
AND   Edges.DeathPhaseID IS NULL
AND   Nodes.DeathPhaseID IS NULL;
RETURN _Count;
END;
$$;
