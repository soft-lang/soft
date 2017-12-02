CREATE OR REPLACE FUNCTION Parent(_NodeID integer)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_ParentNodeID integer;
_Count        bigint;
BEGIN
SELECT  Edges.ParentNodeID,  COUNT(*) OVER ()
INTO         _ParentNodeID, _Count
FROM Edges
INNER JOIN Nodes ON Nodes.NodeID = Edges.ParentNodeID
WHERE Edges.ChildNodeID  = _NodeID
AND   Edges.DeathPhaseID IS NULL
AND   Nodes.DeathPhaseID IS NULL
LIMIT 1;

IF _Count = 0 THEN
    RAISE EXCEPTION 'No parent found for NodeID %', _NodeID;
ELSIF _Count > 1 THEN
    RAISE EXCEPTION 'Multiple parents found for NodeID % Count %', _NodeID, _Count;
END IF;

RETURN _ParentNodeID;
END;
$$;
