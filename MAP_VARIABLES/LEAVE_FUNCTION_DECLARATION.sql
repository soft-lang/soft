CREATE OR REPLACE FUNCTION "MAP_VARIABLES"."LEAVE_FUNCTION_DECLARATION"(_NodeID integer) RETURNS boolean
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
INNER JOIN Nodes     ON Nodes.NodeID         = Edges.ChildNodeID
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
WHERE Edges.ParentNodeID = _NodeID
AND   Edges.DeathPhaseID IS NULL
AND   Nodes.DeathPhaseID IS NULL
AND   NodeTypes.NodeType <> 'CALL';

PERFORM Set_Walkable(_NodeID, FALSE);

UPDATE Programs SET NodeID = _ChildNodeID WHERE ProgramID = _ProgramID AND NodeID = _NodeID RETURNING TRUE INTO STRICT _OK;

RETURN TRUE;
END;
$$;
