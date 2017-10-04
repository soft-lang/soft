CREATE OR REPLACE FUNCTION Node_Type(_NodeID integer)
RETURNS text
LANGUAGE sql
AS $$
SELECT NodeTypes.NodeType
FROM Nodes
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
WHERE Nodes.NodeID = $1
$$;
