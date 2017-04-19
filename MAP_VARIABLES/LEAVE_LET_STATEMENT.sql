CREATE OR REPLACE FUNCTION "MAP_VARIABLES"."LEAVE_LET_STATEMENT"(_NodeID integer) RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID        integer;
_AllocaNodeID     integer;
_IdentifierNodeID integer;
_EdgeID           integer;
_VariableNodeID   integer;
_OK               boolean;
BEGIN

SELECT   Edges.ParentNodeID
INTO STRICT _VariableNodeID
FROM Edges
WHERE Edges.ChildNodeID = _NodeID
AND   Edges.DeathPhaseID IS NULL
ORDER BY Edges.EdgeID
LIMIT 1;

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
WHERE Nodes.NodeID = _VariableNodeID
AND Nodes.NodeTypeID = (SELECT NodeTypeID FROM NodeTypes WHERE NodeType = 'VARIABLE')
AND Nodes.DeathPhaseID          IS NULL
AND Edges.DeathPhaseID          IS NULL
AND IdentifierNode.DeathPhaseID IS NULL;

PERFORM Copy_Node(_FromNodeID := _IdentifierNodeID, _ToNodeID := _VariableNodeID);
PERFORM Kill_Edge(_EdgeID);
PERFORM Kill_Node(_IdentifierNodeID);

IF Find_Node(_NodeID := _VariableNodeID, _Descend := FALSE, _Strict := FALSE, _Path := '-> LET_STATEMENT <- FUNCTION_DECLARATION') IS NULL
THEN
    _AllocaNodeID := Find_Node(_NodeID := _NodeID, _Descend := TRUE, _Strict := TRUE, _Path := '<- ALLOCA');
    PERFORM New_Edge(
        _ProgramID    := _ProgramID,
        _ParentNodeID := _VariableNodeID,
        _ChildNodeID  := _AllocaNodeID
    );
END IF;

PERFORM Set_Visited(_VariableNodeID, NULL);

PERFORM Log(
    _NodeID   := _NodeID,
    _Severity := 'DEBUG2',
    _Message  := format('%s is now declared and can be accessed by ENTER_IDENTIFIER', Colorize(Node(_NodeID), 'CYAN'))
);

RETURN TRUE;
END;
$$;
