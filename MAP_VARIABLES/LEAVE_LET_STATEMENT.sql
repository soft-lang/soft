CREATE OR REPLACE FUNCTION "MAP_VARIABLES"."LEAVE_LET_STATEMENT"(_NodeID integer) RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_IdentifierNodeID integer;
_EdgeID           integer;
_VariableNodeID   integer;
_OK               boolean;
BEGIN

SELECT
    IdentifierNode.NodeID,
    Edges.EdgeID,
    VariableNode.NodeID
INTO STRICT
    _IdentifierNodeID,
    _EdgeID,
    _VariableNodeID
FROM Nodes AS VariableNode
INNER JOIN Edges                   ON Edges.ChildNodeID     = VariableNode.NodeID
INNER JOIN Nodes AS IdentifierNode ON IdentifierNode.NodeID = Edges.ParentNodeID
WHERE VariableNode.NodeID = (
    SELECT Edges.ParentNodeID
    FROM Nodes
    INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
    INNER JOIN Edges     ON Edges.ChildNodeID    = Nodes.NodeID
    WHERE Nodes.NodeID       = _NodeID
    AND   NodeTypes.NodeType = 'LET_STATEMENT'
    AND   Nodes.DeathPhaseID IS NULL
    AND   Edges.DeathPhaseID IS NULL
    ORDER BY Edges.EdgeID
    LIMIT 1
)
AND VariableNode.NodeTypeID = (SELECT NodeTypeID FROM NodeTypes WHERE NodeType = 'VARIABLE')
AND VariableNode.DeathPhaseID   IS NULL
AND Edges.DeathPhaseID          IS NULL
AND IdentifierNode.DeathPhaseID IS NULL;

PERFORM Copy_Node(_FromNodeID := _IdentifierNodeID, _ToNodeID := _VariableNodeID);
PERFORM Kill_Edge(_EdgeID);
PERFORM Kill_Node(_IdentifierNodeID);

PERFORM Log(
    _NodeID   := _NodeID,
    _Severity := 'DEBUG2',
    _Message  := format('%s is now declared and can be accessed by ENTER_IDENTIFIER', Colorize(Node(_VariableNodeID), 'CYAN'))
);

RETURN TRUE;
END;
$$;
