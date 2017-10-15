CREATE OR REPLACE FUNCTION Print_Node(
_NodeID         integer,
_RootNodeID     integer   DEFAULT NULL,
_VisitedEdgeIDs integer[] DEFAULT ARRAY[]::integer[]
) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_EdgeID         integer;
_ParentNodeID   integer;
_PrimitiveValue text;
_Message        text;
BEGIN

_PrimitiveValue := Primitive_Value(_NodeID);

IF _PrimitiveValue IS NOT NULL THEN
    PERFORM Log(
        _NodeID   := _NodeID,
        _Severity := 'STDOUT',
        _Message  := _PrimitiveValue
    );
    RETURN;
END IF;

PERFORM Print_Node(
    _NodeID         := ParentNodeID,
    _RootNodeID     := COALESCE(_RootNodeID,_NodeID),
    _VisitedEdgeIDs := _VisitedEdgeIDs || EdgeID
)
FROM (
    SELECT
        Edges.EdgeID,
        Edges.ParentNodeID
    FROM Edges
    INNER JOIN Nodes AS ParentNode ON ParentNode.NodeID = Edges.ParentNodeID
    INNER JOIN Nodes AS ChildNode  ON ChildNode.NodeID  = Dereference(Edges.ChildNodeID)
    WHERE Edges.ChildNodeID    = _NodeID
    AND NOT Edges.EdgeID       = ANY(_VisitedEdgeIDs)
    AND Edges.DeathPhaseID      IS NULL
    AND ParentNode.DeathPhaseID IS NULL
    AND ChildNode.DeathPhaseID  IS NULL
    ORDER BY Edges.EdgeID
) AS X;

RETURN;
END;
$$;
