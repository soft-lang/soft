CREATE OR REPLACE FUNCTION Child(_NodeID integer)
RETURNS integer
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

IF _Count = 0 THEN
    RAISE EXCEPTION 'No child found for NodeID %', _NodeID;
ELSIF _Count > 1 THEN
    RAISE EXCEPTION 'Multiple children found for NodeID % Count %', _NodeID, _Count;
END IF;

RETURN _ChildNodeID;
END;
$$;
