CREATE OR REPLACE FUNCTION "MAP_VARIABLES"."LEAVE_VARIABLE"(_NodeID integer) RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID        integer;
_IdentifierNodeID integer;
_EdgeID           integer;
_VariableNodeID   integer;
_OK               boolean;
BEGIN

SELECT
    Nodes.ProgramID,
    IdentifierNode.NodeID,
    Edges.EdgeID
INTO STRICT
    _ProgramID,
    _IdentifierNodeID,
    _EdgeID
FROM Nodes
INNER JOIN Edges                   ON Edges.ChildNodeID     = Nodes.NodeID
INNER JOIN Nodes AS IdentifierNode ON IdentifierNode.NodeID = Edges.ParentNodeID
WHERE Nodes.NodeID = _NodeID
AND Nodes.NodeTypeID = (SELECT NodeTypeID FROM NodeTypes WHERE NodeType = 'VARIABLE')
AND Nodes.DeathPhaseID          IS NULL
AND Edges.DeathPhaseID          IS NULL
AND IdentifierNode.DeathPhaseID IS NULL;

PERFORM Copy_Node(_FromNodeID := _IdentifierNodeID, _ToNodeID := _NodeID);
PERFORM Kill_Edge(_EdgeID);
PERFORM Kill_Node(_IdentifierNodeID);

PERFORM Log(
    _NodeID   := _NodeID,
    _Severity := 'DEBUG2',
    _Message  := format('%s is now declared and can be accessed by ENTER_IDENTIFIER', Colorize(Node(_NodeID), 'CYAN'))
);

RETURN TRUE;
END;
$$;
