CREATE OR REPLACE FUNCTION Goto_Parent(_NodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID    integer;
_ParentNodeID integer;
_OK           boolean;
BEGIN

SELECT
    Nodes.ProgramID,
    Edges.ParentNodeID
INTO STRICT
    _ProgramID,
    _ParentNodeID
FROM Edges
INNER JOIN Nodes ON Nodes.NodeID = Edges.ParentNodeID
WHERE Edges.ChildNodeID = _NodeID
AND   Edges.DeathPhaseID IS NULL
AND   Nodes.DeathPhaseID IS NULL;

PERFORM Enter_Node(_ParentNodeID);

RETURN TRUE;
END;
$$;
