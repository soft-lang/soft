CREATE OR REPLACE FUNCTION Has_Child(_NodeID integer, _IsNthParent integer DEFAULT NULL)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_ChildNodeID integer;
_Count       bigint;
BEGIN
SELECT  Edges.ChildNodeID,  COUNT(*) OVER ()
INTO         _ChildNodeID, _Count
FROM Edges
INNER JOIN Nodes ON Nodes.NodeID = Edges.ChildNodeID
WHERE Edges.ParentNodeID  = _NodeID
AND   Edges.DeathPhaseID IS NULL
AND   Nodes.DeathPhaseID IS NULL
LIMIT 1;
IF NOT FOUND THEN
    RETURN FALSE;
ELSIF _Count > 1 THEN
    RAISE EXCEPTION 'Multiple children found for NodeID % Count %', _NodeID, _Count;
END IF;

IF _IsNthParent IS NULL THEN
    RETURN TRUE;
END IF;

RETURN EXISTS (
    SELECT 1 FROM (
        SELECT
            Edges.ParentNodeID,
            ROW_NUMBER() OVER (ORDER BY Edges.EdgeID)
        FROM Edges
        INNER JOIN Nodes ON Nodes.NodeID = Edges.ParentNodeID
        WHERE Edges.ChildNodeID  = _ChildNodeID
        AND   Edges.DeathPhaseID IS NULL
        AND   Nodes.DeathPhaseID IS NULL
    ) AS X
    WHERE X.ParentNodeID = _NodeID
    AND   X.ROW_NUMBER   = _IsNthParent
);
END;
$$;
