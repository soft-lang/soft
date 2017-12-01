CREATE OR REPLACE FUNCTION Copy_Clone(_NodeID integer, _SelfRef boolean, _EnvironmentID integer)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_ClonedRootNodeID integer;
BEGIN

IF NOT (
    SELECT ClonedFromNodeID IS NOT NULL AND ClonedRootNodeID IS NULL
    FROM Nodes
    WHERE NodeID = _NodeID
) THEN
    RETURN NULL;
END IF;

PERFORM Log(
    _NodeID   := _NodeID,
    _Severity := 'DEBUG3',
    _Message  := 'Copy cloning NodeID '||_NodeID::text
);

SELECT New_Node(
    _ProgramID        := ProgramID,
    _NodeTypeID       := NodeTypeID,
    _PrimitiveType    := PrimitiveType,
    _PrimitiveValue   := PrimitiveValue,
    _NodeName         := NodeName,
    _Walkable         := Walkable,
    _ClonedFromNodeID := NodeID,
    _ClonedRootNodeID := NULL,
    _ReferenceNodeID  := ReferenceNodeID,
    _EnvironmentID    := _EnvironmentID
) INTO STRICT _ClonedRootNodeID
FROM Nodes WHERE NodeID = _NodeID;

PERFORM New_Node(
    _ProgramID        := ProgramID,
    _NodeTypeID       := NodeTypeID,
    _PrimitiveType    := PrimitiveType,
    _PrimitiveValue   := PrimitiveValue,
    _NodeName         := NodeName,
    _Walkable         := Walkable,
    _ClonedFromNodeID := NodeID,
    _ClonedRootNodeID := _ClonedRootNodeID,
    _ReferenceNodeID  := ReferenceNodeID,
    _EnvironmentID    := _EnvironmentID
)
FROM Nodes WHERE ClonedRootNodeID = _NodeID;

PERFORM New_Edge(
    _ParentNodeID     := CASE WHEN ParentNodeID = ClonedRootNodeID THEN CASE _SelfRef WHEN TRUE THEN _ClonedRootNodeID WHEN FALSE THEN _NodeID END ELSE COALESCE((SELECT Nodes.NodeID FROM Nodes WHERE Nodes.ClonedRootNodeID = _ClonedRootNodeID AND Nodes.ClonedFromNodeID = Edges.ParentNodeID), ParentNodeID) END,
    _ChildNodeID      := CASE WHEN ChildNodeID  = ClonedRootNodeID THEN _ClonedRootNodeID ELSE COALESCE((SELECT Nodes.NodeID FROM Nodes WHERE Nodes.ClonedRootNodeID = _ClonedRootNodeID AND Nodes.ClonedFromNodeID = Edges.ChildNodeID),  ChildNodeID) END,
    _ClonedFromEdgeID := EdgeID,
    _ClonedRootNodeID := _ClonedRootNodeID,
    _EnvironmentID    := _EnvironmentID
)
FROM Edges
WHERE ClonedRootNodeID = _NodeID;

RETURN _ClonedRootNodeID;
END;
$$;
