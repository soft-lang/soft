CREATE OR REPLACE FUNCTION Pop_Node(_VariableNodeID integer, _StackNodeType text DEFAULT 'STACK')
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_StackNodeTypeID integer;
_StackEdgeID     integer;
_StackNodeID     integer;
_OK              boolean;
BEGIN

SELECT StackNodeType.NodeTypeID
INTO STRICT    _StackNodeTypeID
FROM Nodes
INNER JOIN NodeTypes AS VariableNodeType ON VariableNodeType.NodeTypeID = Nodes.NodeTypeID
INNER JOIN NodeTypes AS StackNodeType    ON StackNodeType.LanguageID    = VariableNodeType.LanguageID
WHERE Nodes.NodeID           = _VariableNodeID
AND   StackNodeType.NodeType = _StackNodeType
AND   Nodes.DeathPhaseID     IS NULL;

SELECT
    Edges.EdgeID,
    Edges.ParentNodeID
INTO
    _StackEdgeID,
    _StackNodeID
FROM Edges
INNER JOIN Nodes ON Nodes.NodeID = Edges.ParentNodeID
WHERE Edges.ChildNodeID  = _VariableNodeID
AND   Nodes.NodeTypeID   = _StackNodeTypeID
AND   Edges.DeathPhaseID IS NULL
AND   Nodes.DeathPhaseID IS NULL;
IF NOT FOUND THEN
    RAISE EXCEPTION 'Unable to pop % since it has no parent stack node', _VariableNodeID;
END IF;

PERFORM Copy_Node(_StackNodeID, _VariableNodeID);

PERFORM Kill_Edge(_StackEdgeID);

SELECT Edges.EdgeID
INTO   _StackEdgeID
FROM Edges
INNER JOIN Nodes ON Nodes.NodeID = Edges.ParentNodeID
WHERE Edges.ChildNodeID  = _StackNodeID
AND   Nodes.NodeTypeID   = _StackNodeTypeID
AND   Edges.DeathPhaseID IS NULL
AND   Nodes.DeathPhaseID IS NULL;
IF FOUND THEN
    PERFORM Set_Edge_Child(_EdgeID := _StackEdgeID, _ChildNodeID := _VariableNodeID);
END IF;

PERFORM Kill_Node(_StackNodeID);

RETURN TRUE;
END;
$$;
