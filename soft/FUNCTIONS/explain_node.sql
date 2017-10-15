CREATE OR REPLACE FUNCTION Explain_Node(
_NodeID         integer,
_RootNodeID     integer   DEFAULT NULL,
_VisitedEdgeIDs integer[] DEFAULT ARRAY[]::integer[]
) RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
_EdgeID         integer;
_ParentNodeID   integer;
_PrimitiveValue text;
_Message        text;
_Arguments      text;
BEGIN

IF NOT (SELECT Walkable FROM Nodes WHERE NodeID = _NodeID) THEN
    RETURN Primitive_Value(_NodeID);
END IF;

SELECT string_agg(Explain_Node(
    _NodeID         := ParentNodeID,
    _RootNodeID     := COALESCE(_RootNodeID, _NodeID),
    _VisitedEdgeIDs := _VisitedEdgeIDs || EdgeID
), ',')
INTO _Arguments
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

RETURN format('%s(%s)', Node_Type(_NodeID), _Arguments);
END;
$$;
