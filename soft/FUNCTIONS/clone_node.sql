CREATE OR REPLACE FUNCTION Clone_Node(_NodeID integer, _ClonedRootNodeID integer DEFAULT NULL, _Depth integer DEFAULT 0, _VisitedNodes integer[] DEFAULT ARRAY[]::integer[])
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_ClonedNodeID    integer;
_ParentNodeID    integer;
BEGIN

RAISE NOTICE 'Clone_Node NodeID % ClonedRootNodeID % Depth %', _NodeID, _ClonedRootNodeID, _Depth;

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
            CASE Languages.VariableBinding
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
            _ProgramID        := Nodes.ProgramID,
            _NodeTypeID       := Nodes.NodeTypeID,
            _TerminalType     := Nodes.TerminalType,
            _TerminalValue    := Nodes.TerminalValue,
            _Visited          := Nodes.Visited,
            _ClonedFromNodeID := Nodes.NodeID,
            _ClonedRootNodeID := _ClonedRootNodeID
        )
    )
INTO STRICT
    _ClonedNodeID
FROM Nodes
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
INNER JOIN Languages ON Languages.LanguageID = NodeTypes.LanguageID
WHERE NodeID = _NodeID;

IF _ClonedRootNodeID IS NULL THEN
    _ClonedRootNodeID := _ClonedNodeID;
END IF;

PERFORM New_Edge(
    _ProgramID    := ProgramID,
    _ParentNodeID := Clone_Node(
        _NodeID           := ParentNodeID,
        _ClonedRootNodeID := _ClonedRootNodeID,
        _Depth            := _Depth + 1,
        _VisitedNodes     := _VisitedNodes || _NodeID
    ),
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
    AND NOT Edges.ParentNodeID = ANY(_VisitedNodes)
    AND Edges.DeathPhaseID IS NULL
    AND Nodes.DeathPhaseID IS NULL
    ORDER BY Edges.EdgeID
) AS X;

PERFORM Log(
    _NodeID   := _NodeID,
    _Severity := 'DEBUG3',
    _Message  := format('Cloned %s -> %s Depth %s %s', Colorize(Node(_NodeID),'CYAN'), Colorize(Node(_ClonedNodeID),'CYAN'), _Depth, _VisitedNodes)
);

RETURN _ClonedNodeID;
END;
$$;
