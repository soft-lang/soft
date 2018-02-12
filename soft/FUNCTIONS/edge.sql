CREATE OR REPLACE FUNCTION Edge(_ParentNodeID integer, _ChildNodeID integer)
RETURNS integer
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
_EdgeID integer;
_Count  bigint;
BEGIN
SELECT  Edges.EdgeID,  COUNT(*) OVER ()
INTO         _EdgeID, _Count
FROM Edges
INNER JOIN Nodes AS Parent ON Parent.NodeID = Edges.ParentNodeID
INNER JOIN Nodes AS Child  ON Child.NodeID  = Edges.ChildNodeID
WHERE Edges.ParentNodeID  = _ParentNodeID
AND   Edges.ChildNodeID   = _ChildNodeID
AND   Edges.DeathPhaseID  IS NULL
AND   Parent.DeathPhaseID IS NULL
AND   Child.DeathPhaseID  IS NULL
LIMIT 1;

IF _Count = 0 THEN
    RAISE EXCEPTION 'No edge found from ParentNodeID % to ChildNodeID %', _ParentNodeID, _ChildNodeID;
ELSIF _Count > 1 THEN
    RAISE EXCEPTION 'Multiple edges found from ParentNodeID % to ChildNodeID % Count %', _ParentNodeID, _ChildNodeID, _Count;
END IF;

RETURN _EdgeID;
END;
$$;
