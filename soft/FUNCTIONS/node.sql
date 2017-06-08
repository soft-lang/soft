CREATE OR REPLACE FUNCTION Node(_NodeID integer)
RETURNS text
LANGUAGE sql
AS $$
SELECT format('%s%s%s', NodeTypes.NodeType, Nodes.NodeID, '['||Nodes.PrimitiveType::text||']') FROM Nodes
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
WHERE Nodes.NodeID = $1
$$;
