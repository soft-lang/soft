CREATE OR REPLACE FUNCTION Clone_Node(_NodeID integer, _OriginRootNodeID integer DEFAULT NULL, _ClonedRootNodeID integer DEFAULT NULL, _WalkableNodes integer[] DEFAULT ARRAY[]::integer[], _SelfRef boolean DEFAULT TRUE, _ExcludeEdgeIDs integer[] DEFAULT NULL)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_ClonedNodeID    integer;
_ParentNodeID    integer;
_VariableBinding variablebinding;
_OutOfScope      boolean;
BEGIN

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
SELECT EXISTS (
    SELECT ChildNodeID FROM Edges WHERE ParentNodeID = _NodeID AND DeathPhaseID IS NULL
    EXCEPT
    SELECT ParentNodeID FROM Parents
) INTO STRICT _OutOfScope;

_VariableBinding := (Language(_NodeID)).VariableBinding;

-- Create new node (THEN branch) or reference existing node (ELSE branch)?
IF _ClonedRootNodeID IS NULL -- Always create new node for first node
OR _OutOfScope       IS FALSE
OR _VariableBinding  = 'CAPTURE_BY_VALUE' -- Always create new nodes in this mode
THEN
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
    FROM Nodes
    WHERE NodeID = _NodeID;
ELSIF _ClonedRootNodeID IS NOT NULL
AND   _OutOfScope       IS TRUE
AND   _VariableBinding  = 'CAPTURE_BY_REFERENCE'
THEN
    _ClonedNodeID := _NodeID;
    -- Don't recurse to parents since this node is references
    -- and all its parent nodes will therefore also be references
    -- e.g. if the node is a complex object such as a function declaration
    RAISE NOTICE 'NodeID % have children that are out of scope, so not creating new node nor edges for parents', _NodeID;
    RETURN _ClonedNodeID;
ELSE
    RAISE EXCEPTION 'How did we end up here!? ClonedRootNodeID % VariableBinding % OutOfScope %', _ClonedRootNodeID, _VariableBinding, _OutOfScope;
END IF;

IF _ClonedRootNodeID IS NULL THEN
    _ClonedRootNodeID := _ClonedNodeID;
    _OriginRootNodeID := _NodeID;
END IF;

RAISE NOTICE 'New_Edges for ClonedNodeID % NodeID % WalkableNodes % OriginRootNodeID %', _ClonedNodeID, _NodeID, _WalkableNodes, _OriginRootNodeID;

PERFORM New_Edge(
    _ProgramID    := ProgramID,
    _ParentNodeID := CASE
        WHEN ParentNodeID = _OriginRootNodeID
        THEN CASE WHEN _SelfRef THEN _ClonedRootNodeID ELSE _OriginRootNodeID END
        ELSE Clone_Node(
            _NodeID           := ParentNodeID,
            _OriginRootNodeID := _OriginRootNodeID,
            _ClonedRootNodeID := _ClonedRootNodeID,
            _WalkableNodes    := _WalkableNodes || _NodeID,
            _SelfRef          := _SelfRef,
            _ExcludeEdgeIDs   := _ExcludeEdgeIDs
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
    INNER JOIN Nodes ON Nodes.NodeID = Edges.ParentNodeID
    WHERE Edges.ChildNodeID    = _NodeID
--    AND (NOT Edges.ParentNodeID = ANY(_WalkableNodes)
--         OR  Edges.ParentNodeID = _OriginRootNodeID)
    AND Edges.DeathPhaseID IS NULL
    AND Nodes.DeathPhaseID IS NULL
    AND (Edges.EdgeID = ANY(_ExcludeEdgeIDs)) IS NOT TRUE
    ORDER BY Edges.EdgeID
) AS X;

PERFORM Log(
    _NodeID   := _NodeID,
    _Severity := 'DEBUG3',
    _Message  := format('Cloned %s -> %s', Colorize(Node(_NodeID),'CYAN'), Colorize(Node(_ClonedNodeID),'CYAN'))
);

RETURN _ClonedNodeID;
END;
$$;
