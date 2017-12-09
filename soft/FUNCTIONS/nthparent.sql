CREATE OR REPLACE FUNCTION NthParent(_NodeID integer, _Nth integer, _AssertNodeType text DEFAULT NULL)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_ParentNodeID integer;
_NodeType     text;
BEGIN
SELECT
    ParentNodeID,
    NodeType
INTO
    _ParentNodeID,
    _NodeType
FROM (
    SELECT
        Edges.ParentNodeID,
        NodeTypes.NodeType,
        ROW_NUMBER() OVER (ORDER BY Edges.EdgeID)
    FROM Edges
    INNER JOIN Nodes     ON Nodes.NodeID         = Edges.ParentNodeID
    INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
    WHERE Edges.ChildNodeID  = _NodeID
    AND   Edges.DeathPhaseID IS NULL
    AND   Nodes.DeathPhaseID IS NULL
) AS X
WHERE ROW_NUMBER = _Nth;
IF NOT FOUND THEN
    RAISE EXCEPTION 'Unable to find NthParent NodeID % Nth % AssertNodeType %', _NodeID, _Nth, _AssertNodeType;
END IF;

IF _NodeType <> _AssertNodeType THEN
    RAISE EXCEPTION 'NodeType % does not match AssertNodeType %, NodeID % Nth %', _NodeType, _AssertNodeType, _NodeID, _Nth;
END IF;

RETURN _ParentNodeID;
END;
$$;
