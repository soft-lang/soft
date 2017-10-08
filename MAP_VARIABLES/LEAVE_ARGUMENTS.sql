CREATE OR REPLACE FUNCTION "MAP_VARIABLES"."LEAVE_ARGUMENTS"(_NodeID integer)
RETURNS boolean
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

_AllocaNodeID := Find_Node(_NodeID := _NodeID, _Descend := FALSE, _Strict := TRUE, _Path := '-> FUNCTION_DECLARATION <- ALLOCA');

FOR _VariableNodeID IN
SELECT   Edges.ParentNodeID
FROM Edges
WHERE Edges.ChildNodeID = _NodeID
AND   Edges.DeathPhaseID IS NULL
ORDER BY Edges.EdgeID
LOOP

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

    UPDATE Nodes AS CopyTo SET
        PrimitiveType  = CopyFrom.PrimitiveType,
        PrimitiveValue = CopyFrom.PrimitiveValue
    FROM Nodes AS CopyFrom
    WHERE CopyFrom.NodeID = _IdentifierNodeID
    AND     CopyTo.NodeID = _VariableNodeID
    RETURNING TRUE INTO STRICT _OK;

    PERFORM Kill_Edge(_EdgeID);
    PERFORM Kill_Node(_IdentifierNodeID);

    PERFORM New_Edge(
        _ParentNodeID := _VariableNodeID,
        _ChildNodeID  := _AllocaNodeID
    );

    PERFORM Set_Walkable(_VariableNodeID, FALSE);

    PERFORM Log(
        _NodeID   := _NodeID,
        _Severity := 'DEBUG2',
        _Message  := format('%s is now declared and can be accessed by ENTER_IDENTIFIER', Colorize(Node(_VariableNodeID), 'CYAN'))
    );

END LOOP;

RETURN TRUE;
END;
$$;