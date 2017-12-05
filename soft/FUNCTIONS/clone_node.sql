CREATE OR REPLACE FUNCTION Clone_Node(_NodeID integer, _OriginRootNodeID integer DEFAULT NULL, _ClonedRootNodeID integer DEFAULT NULL, _ClonedEdgeIDs integer[] DEFAULT ARRAY[]::integer[], _SelfRef boolean DEFAULT TRUE, _VariableBinding variablebinding DEFAULT NULL, _EnvironmentID integer DEFAULT 0)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_ClonedNodeID       integer;
_EdgeID             integer;
_ParentNodeID       integer;
_ClonedParentNodeID integer;
BEGIN

IF _VariableBinding IS NULL THEN
    _VariableBinding := (Language(_NodeID)).VariableBinding;
END IF;

SELECT      NodeID
INTO _ClonedNodeID
FROM Nodes
WHERE ClonedRootNodeID = _ClonedRootNodeID
AND   ClonedFromNodeID = _NodeID;
IF FOUND THEN
    RETURN _ClonedNodeID;
END IF;

IF _ClonedRootNodeID IS NULL THEN
    PERFORM Log(
        _NodeID   := _NodeID,
        _Severity := 'DEBUG3',
        _Message  := 'First node, create new'
    );
ELSE
    IF _VariableBinding = 'CAPTURE_BY_VALUE' THEN
        -- Always copy
    ELSIF _VariableBinding = 'CAPTURE_BY_REFERENCE' THEN
        IF Out_Of_Scope(_FromNodeID := _ClonedRootNodeID, _ToNodeID := _NodeID) THEN
            PERFORM Log(
                _NodeID   := _NodeID,
                _Severity := 'DEBUG3',
                _Message  := format('Node %s (NodeID %s) is out of scope (OriginRootNode %s, ClonedRootNode %s)', Colorize(Node(_NodeID),'CYAN'), _NodeID, Node(_OriginRootNodeID), Node(_ClonedRootNodeID))
            );
            _ClonedNodeID := Dereference(_NodeID);
            RETURN _ClonedNodeID;
        END IF;
    END IF;
END IF;

IF _ClonedNodeID IS NULL THEN
    SELECT New_Node(
        _ProgramID        := ProgramID,
        _NodeTypeID       := NodeTypeID,
        _PrimitiveType    := PrimitiveType,
        _PrimitiveValue   := PrimitiveValue,
        _NodeName         := NodeName,
        _Closure          := Closure,
        _Walkable         := Walkable,
        _ClonedFromNodeID := NodeID,
        _ClonedRootNodeID := _ClonedRootNodeID,
        _ReferenceNodeID  := ReferenceNodeID,
        _EnvironmentID    := _EnvironmentID
    ) INTO STRICT _ClonedNodeID
    FROM Nodes WHERE NodeID = _NodeID;
END IF;

IF _ClonedRootNodeID IS NULL THEN
    _ClonedRootNodeID := _ClonedNodeID;
    _OriginRootNodeID := _NodeID;
END IF;

FOR
    _EdgeID,
    _ParentNodeID
IN
    SELECT
        Edges.EdgeID,
        Edges.ParentNodeID
    FROM Edges
    INNER JOIN Nodes AS ParentNode ON ParentNode.NodeID = Edges.ParentNodeID
    INNER JOIN Nodes AS ChildNode  ON ChildNode.NodeID  = Dereference(Edges.ChildNodeID)
    WHERE Edges.ChildNodeID    = _NodeID
    AND (NOT Edges.EdgeID       = ANY(_ClonedEdgeIDs)
         OR  Edges.ParentNodeID = _OriginRootNodeID)
    AND Edges.DeathPhaseID      IS NULL
    AND ParentNode.DeathPhaseID IS NULL
    AND ChildNode.DeathPhaseID  IS NULL
    ORDER BY Edges.EdgeID
LOOP
    IF _ParentNodeID = _OriginRootNodeID THEN
        IF _SelfRef THEN
            _ClonedParentNodeID := _ClonedRootNodeID;
        ELSE
            _ClonedParentNodeID := _OriginRootNodeID;
        END IF;
    ELSE
        _ClonedParentNodeID := Clone_Node(
            _NodeID           := _ParentNodeID,
            _OriginRootNodeID := _OriginRootNodeID,
            _ClonedRootNodeID := _ClonedRootNodeID,
            _ClonedEdgeIDs    := _ClonedEdgeIDs || _EdgeID,
            _SelfRef          := _SelfRef,
            _VariableBinding  := _VariableBinding,
            _EnvironmentID    := _EnvironmentID
        );
    END IF;
    PERFORM New_Edge(
        _ParentNodeID     := _ClonedParentNodeID,
        _ChildNodeID      := _ClonedNodeID,
        _ClonedFromEdgeID := _EdgeID,
        _ClonedRootNodeID := _ClonedRootNodeID,
        _EnvironmentID    := _EnvironmentID
    );
END LOOP;

PERFORM Log(
    _NodeID   := _NodeID,
    _Severity := 'DEBUG3',
    _Message  := format('Cloned %s -> %s (OriginRootNode %s, ClonedRootNode %s)', Colorize(Node(_NodeID),'CYAN'), Colorize(Node(_ClonedNodeID),'CYAN'), Node(_OriginRootNodeID), Node(_ClonedRootNodeID))
);

RETURN _ClonedNodeID;
END;
$$;
