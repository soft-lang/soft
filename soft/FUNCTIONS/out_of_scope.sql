CREATE OR REPLACE FUNCTION Out_Of_Scope(_FromNodeID integer, _ToNodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_OutOfScope boolean;
BEGIN
WITH RECURSIVE Parents AS (
    SELECT
        Nodes.ClonedFromNodeID        AS ParentNodeID,
        ARRAY[Nodes.ClonedFromNodeID] AS ParentNodeIDs
    FROM Nodes
    WHERE Nodes.NodeID = _FromNodeID
    UNION ALL
    SELECT
        Edges.ParentNodeID,
        Edges.ParentNodeID || Parents.ParentNodeIDs AS ParentNodeIDs
    FROM Edges
    INNER JOIN Nodes AS ParentNode ON ParentNode.NodeID    = Edges.ParentNodeID
    INNER JOIN Parents             ON Parents.ParentNodeID = Edges.ChildNodeID
    WHERE    Edges.DeathPhaseID IS NULL
    AND ParentNode.DeathPhaseID IS NULL
    AND NOT Edges.ParentNodeID = ANY(Parents.ParentNodeIDs)
)
SELECT EXISTS (
    SELECT ChildNodeID FROM Edges WHERE ParentNodeID = _ToNodeID AND DeathPhaseID IS NULL
    EXCEPT
    SELECT ParentNodeID FROM Parents
) INTO _OutOfScope;

RETURN _OutOfScope;
END;
$$;
