CREATE OR REPLACE FUNCTION Goto_Child(_NodeID integer)
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

UPDATE Programs SET NodeID = _ChildNodeID WHERE ProgramID = _ProgramID RETURNING TRUE INTO STRICT _OK;

RETURN TRUE;
END;
$$;
