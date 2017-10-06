CREATE OR REPLACE FUNCTION Get_Program_Node(_ProgramID integer)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_NodeID integer;
BEGIN
SELECT Nodes.NodeID
INTO STRICT _NodeID
FROM Nodes
WHERE Nodes.ProgramID = _ProgramID
AND   Nodes.DeathPhaseID     IS NULL
AND   Nodes.ClonedFromNodeID IS NULL
AND   Nodes.ClonedRootNodeID IS NULL
AND NOT EXISTS (SELECT 1 FROM Edges WHERE Edges.DeathPhaseID IS NULL AND Edges.ParentNodeID = Nodes.NodeID);
RETURN _NodeID;
END;
$$;
