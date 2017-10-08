CREATE OR REPLACE FUNCTION Descend(_NodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID   integer;
_ChildNodeID integer;
_OK          boolean;
BEGIN

SELECT
    Nodes.ProgramID,
    Edges.ChildNodeID
INTO STRICT
    _ProgramID,
    _ChildNodeID
FROM Edges
INNER JOIN Nodes ON Nodes.NodeID = Edges.ChildNodeID
WHERE Edges.ParentNodeID = _NodeID
AND   Edges.DeathPhaseID IS NULL
AND   Nodes.DeathPhaseID IS NULL;

PERFORM Set_Program_Node(_ChildNodeID);

RETURN TRUE;
END;
$$;
