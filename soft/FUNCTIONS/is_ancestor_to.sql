CREATE OR REPLACE FUNCTION Is_Ancestor_To(_AncestorNodeID integer, _DescendantNodeID integer)
RETURNS boolean
LANGUAGE sql
AS $$
WITH RECURSIVE Children AS (
    SELECT
        Edges.ChildNodeID,
        ARRAY[Edges.ChildNodeID] AS ChildNodeIDs
    FROM Edges
    INNER JOIN Nodes AS ChildNode ON ChildNode.NodeID = Edges.ChildNodeID
    WHERE Edges.ParentNodeID     = $1
    AND   Edges.DeathPhaseID     IS NULL
    AND   ChildNode.DeathPhaseID IS NULL
    AND   ChildNode.Walkable     IS TRUE
    UNION ALL
    SELECT
        Edges.ChildNodeID,
        Edges.ChildNodeID || Children.ChildNodeIDs AS ChildNodeIDs
    FROM Edges
    INNER JOIN Nodes AS ChildNode ON ChildNode.NodeID     = Edges.ChildNodeID
    INNER JOIN Children           ON Children.ChildNodeID = Edges.ParentNodeID
    WHERE    Edges.DeathPhaseID IS NULL
    AND ChildNode.DeathPhaseID IS NULL
    AND NOT Edges.ChildNodeID = ANY(Children.ChildNodeIDs)
)
SELECT EXISTS (
    SELECT 1
    FROM Children
    WHERE ChildNodeID = $2
)
$$;
