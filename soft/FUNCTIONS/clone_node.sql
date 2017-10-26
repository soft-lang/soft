CREATE OR REPLACE FUNCTION Clone_Node(_NodeID integer, _OriginRootNodeID integer DEFAULT NULL, _ClonedRootNodeID integer DEFAULT NULL, _ClonedEdgeIDs integer[] DEFAULT ARRAY[]::integer[], _SelfRef boolean DEFAULT TRUE, _ToNodeID integer DEFAULT NULL)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_ClonedNodeID       integer;
_EdgeID             integer;
_ParentNodeID       integer;
_ClonedParentNodeID integer;
_OutOfScope         boolean;
_ToNodeOutOfScope   boolean;
BEGIN

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
        _Message  := 'First node, create new'||_ToNodeID::text
    );
ELSE
    IF (Language(_NodeID)).VariableBinding = 'CAPTURE_BY_VALUE' THEN
        -- Always copy
    ELSIF (Language(_NodeID)).VariableBinding = 'CAPTURE_BY_REFERENCE' THEN
        IF _ToNodeID IS NOT NULL THEN
            WITH RECURSIVE Parents AS (
                SELECT
                    Nodes.ClonedFromNodeID        AS ParentNodeID,
                    ARRAY[Nodes.ClonedFromNodeID] AS ParentNodeIDs
                FROM Nodes
                WHERE Nodes.NodeID = _NodeID
                UNION ALL
                SELECT
                    Edges.ParentNodeID,
                    Edges.ParentNodeID || Parents.ParentNodeIDs AS ParentNodeIDs
                FROM Edges
                INNER JOIN Nodes AS ParentNode ON ParentNode.NodeID    = Edges.ParentNodeID
                INNER JOIN Parents             ON Parents.ParentNodeID = Edges.ChildNodeID
                WHERE    Edges.DeathPhaseID IS NULL
                AND ParentNode.DeathPhaseID IS NULL
                AND NOT Edges.ParentNodeID = ANY(Parents.ParentNodeIDs)
            )
            SELECT EXISTS (
                SELECT ChildNodeID FROM Edges WHERE ParentNodeID = _ToNodeID AND DeathPhaseID IS NULL
                EXCEPT
                SELECT ParentNodeID FROM Parents
            ) INTO _ToNodeOutOfScope;
        END IF;

        WITH RECURSIVE Parents AS (
            SELECT
                Nodes.ClonedFromNodeID        AS ParentNodeID,
                ARRAY[Nodes.ClonedFromNodeID] AS ParentNodeIDs
            FROM Nodes
            WHERE Nodes.NodeID = _ClonedRootNodeID
            UNION ALL
            SELECT
                Edges.ParentNodeID,
                Edges.ParentNodeID || Parents.ParentNodeIDs AS ParentNodeIDs
            FROM Edges
            INNER JOIN Nodes AS ParentNode ON ParentNode.NodeID    = Edges.ParentNodeID
            INNER JOIN Parents             ON Parents.ParentNodeID = Edges.ChildNodeID
            WHERE    Edges.DeathPhaseID IS NULL
            AND ParentNode.DeathPhaseID IS NULL
            AND NOT Edges.ParentNodeID = ANY(Parents.ParentNodeIDs)
        )
        SELECT EXISTS (
            SELECT ChildNodeID FROM Edges WHERE ParentNodeID = _NodeID AND DeathPhaseID IS NULL
            EXCEPT
            SELECT ParentNodeID FROM Parents
        ) INTO _OutOfScope;
        IF _OutOfScope
        AND _ToNodeOutOfScope IS NOT TRUE
        THEN
            PERFORM Log(
                _NodeID   := _NodeID,
                _Severity := 'DEBUG3',
                _Message  := format('Node %s (NodeID %s) is out of scope (OriginRootNode %s, ClonedRootNode %s)', Colorize(Node(_NodeID),'CYAN'), _NodeID, Node(_OriginRootNodeID), Node(_ClonedRootNodeID))
            );
            _ClonedNodeID := _NodeID;
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
        _Walkable         := Walkable,
        _ClonedFromNodeID := NodeID,
        _ClonedRootNodeID := _ClonedRootNodeID,
        _ReferenceNodeID  := ReferenceNodeID
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
    AND ChildNode.PrimitiveType IS NULL
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
            _ToNodeID         := _ToNodeID
        );
    END IF;
    PERFORM New_Edge(
        _ParentNodeID := _ClonedParentNodeID,
        _ChildNodeID  := _ClonedNodeID
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
