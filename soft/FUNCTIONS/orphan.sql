CREATE OR REPLACE FUNCTION Orphan(_NodeID integer)
RETURNS boolean
LANGUAGE sql
AS $$
SELECT NOT EXISTS (
    SELECT 1
    FROM Edges
    INNER JOIN Nodes ON Nodes.NodeID = Edges.ParentNodeID
    WHERE Edges.ChildNodeID  = Dereference($1)
    AND   Edges.DeathPhaseID IS NULL
    AND   Nodes.DeathPhaseID IS NULL
)
$$;
