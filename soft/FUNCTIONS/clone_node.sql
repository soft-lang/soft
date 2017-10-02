CREATE OR REPLACE FUNCTION Clone_Node(_NodeID integer, _OriginRootNodeID integer DEFAULT NULL, _ClonedRootNodeID integer DEFAULT NULL, _ClonedEdgeIDs integer[] DEFAULT ARRAY[]::integer[], _SelfRef boolean DEFAULT TRUE)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_ClonedNodeID integer;
_ParentNodeID integer;
BEGIN

-- RAISE NOTICE '=>Clone_Node % (OriginRootNodeID %, ClonedRootNodeID %)', Get_Node_Label(_NodeID), Get_Node_Label(_OriginRootNodeID), Get_Node_Label(_ClonedRootNodeID);

SELECT      NodeID
INTO _ClonedNodeID
FROM Nodes
WHERE ClonedRootNodeID = _ClonedRootNodeID
AND   ClonedFromNodeID = _NodeID;
IF FOUND THEN
    RETURN _ClonedNodeID;
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
SELECT
    COALESCE(
        CASE WHEN _ClonedRootNodeID IS NULL
        THEN NULL -- create new node, first node
        ELSE
            CASE (Language(_NodeID)).VariableBinding
            WHEN 'CAPTURE_BY_VALUE'
            THEN NULL -- create new node, copy value instead of referencing it
            WHEN 'CAPTURE_BY_REFERENCE'
            THEN
                CASE
                WHEN EXISTS ( -- any children nodes out of scope?
                    SELECT ChildNodeID FROM Edges WHERE ParentNodeID = _NodeID AND DeathPhaseID IS NULL
                    EXCEPT
                    SELECT ParentNodeID FROM Parents
                )
                THEN _NodeID
                ELSE NULL -- create new node, node is in scope
                END
            END
        END,
        New_Node(
            _ProgramID        := ProgramID,
            _NodeTypeID       := NodeTypeID,
            _PrimitiveType    := PrimitiveType,
            _PrimitiveValue   := PrimitiveValue,
            _Walkable         := Walkable,
            _ClonedFromNodeID := NodeID,
            _ClonedRootNodeID := _ClonedRootNodeID,
            _ReferenceNodeID  := ReferenceNodeID
        )
    )
INTO STRICT
    _ClonedNodeID
FROM Nodes
WHERE NodeID = _NodeID;

IF _ClonedRootNodeID IS NULL THEN
    _ClonedRootNodeID := _ClonedNodeID;
    _OriginRootNodeID := _NodeID;
END IF;

PERFORM New_Edge(
    _ProgramID    := ProgramID,
    _ParentNodeID := CASE
        WHEN ParentNodeID = _OriginRootNodeID
        THEN CASE WHEN _SelfRef THEN _ClonedRootNodeID ELSE _OriginRootNodeID END
        ELSE Clone_Node(
            _NodeID           := ParentNodeID,
            _OriginRootNodeID := _OriginRootNodeID,
            _ClonedRootNodeID := _ClonedRootNodeID,
            _ClonedEdgeIDs    := _ClonedEdgeIDs || EdgeID,
            _SelfRef          := _SelfRef
        )
    END,
    _ChildNodeID      := _ClonedNodeID,
    _ClonedRootNodeID := _ClonedRootNodeID
)
FROM (
    SELECT
        Edges.EdgeID,
        Edges.ProgramID,
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
) AS X;

PERFORM Log(
    _NodeID   := _NodeID,
    _Severity := 'DEBUG3',
    _Message  := format('Cloned %s -> %s', Colorize(Node(_NodeID),'CYAN'), Colorize(Node(_ClonedNodeID),'CYAN'))
);

-- RAISE NOTICE '<=Clone_Node % (OriginRootNodeID %, ClonedRootNodeID %)', Get_Node_Label(_NodeID), Get_Node_Label(_OriginRootNodeID), Get_Node_Label(_ClonedRootNodeID);

RETURN _ClonedNodeID;
END;
$$;
