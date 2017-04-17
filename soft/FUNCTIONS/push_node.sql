CREATE OR REPLACE FUNCTION Push_Node(_VariableNodeID integer, _StackNodeType text DEFAULT 'STACK')
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_StackNodeTypeID integer;
_StackEdgeID     integer;
_StackNodeID     integer;
_ProgramID       integer;
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
    ProgramID,
    New_Node(
        _ProgramID     := ProgramID,
        _NodeTypeID    := _StackNodeTypeID,
        _TerminalType  := TerminalType,
        _TerminalValue := TerminalValue,
        _Walkable      := FALSE
    )
INTO STRICT
    _ProgramID,
    _StackNodeID
FROM Nodes WHERE NodeID = _VariableNodeID;

PERFORM Copy_Node(_VariableNodeID, _StackNodeID);

UPDATE Nodes SET
    TerminalType  = NULL,
    TerminalValue = NULL
WHERE NodeID = _VariableNodeID
AND DeathPhaseID IS NULL
RETURNING TRUE INTO STRICT _OK;

SELECT Edges.EdgeID
INTO   _StackEdgeID
FROM Edges
INNER JOIN Nodes ON Nodes.NodeID = Edges.ParentNodeID
WHERE Edges.ChildNodeID  = _VariableNodeID
AND   Nodes.NodeTypeID   = _StackNodeTypeID
AND   Edges.DeathPhaseID IS NULL
AND   Nodes.DeathPhaseID IS NULL;
IF FOUND THEN
    PERFORM Set_Edge_Child(_EdgeID := _StackEdgeID, _ChildNodeID := _StackNodeID);
END IF;

PERFORM New_Edge(
    _ProgramID    := _ProgramID,
    _ParentNodeID := _StackNodeID,
    _ChildNodeID  := _VariableNodeID
);

RETURN TRUE;
END;
$$;
