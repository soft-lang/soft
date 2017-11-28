CREATE OR REPLACE FUNCTION "MAP_VARIABLES"."LEAVE_CLASS_DECLARATION"(_NodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID        integer;
_AllocaNodeID     integer;
_IdentifierNodeID integer;
_IdentifierEdgeID integer;
_VariableNodeID   integer;
_VariableEdgeID   integer;
_MethodNodeID     integer;
_MethodEdgeID     integer;
_OK               boolean;
BEGIN

LOOP
    SELECT
        Edges.ParentNodeID,
        Edges.EdgeiD
    INTO
        _VariableNodeID,
        _VariableEdgeID
    FROM Edges
    WHERE Edges.ChildNodeID  = _NodeID
    AND  (Edges.EdgeID       > _MethodEdgeID OR _MethodEdgeID IS NULL)
    AND   Edges.DeathPhaseID IS NULL
    ORDER BY Edges.EdgeID
    LIMIT 1;
    IF NOT FOUND THEN
        EXIT;
    END IF;

    SELECT
        Edges.ParentNodeID,
        Edges.EdgeiD
    INTO STRICT
        _MethodNodeID,
        _MethodEdgeID
    FROM Edges
    WHERE Edges.ChildNodeID  = _NodeID
    AND   Edges.EdgeID       > _VariableEdgeID
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
        _IdentifierEdgeID
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

    PERFORM Kill_Edge(_IdentifierEdgeID);
    PERFORM Kill_Node(_IdentifierNodeID);

    PERFORM Set_Walkable(_VariableNodeID, FALSE);

    PERFORM Log(
        _NodeID   := _NodeID,
        _Severity := 'DEBUG2',
        _Message  := format('Method %s is now declared', Colorize(Node(_VariableNodeID), 'GREEN'))
    );
END LOOP;

PERFORM Set_Walkable(_NodeID, FALSE);

RETURN TRUE;
END;
$$;
