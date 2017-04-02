CREATE OR REPLACE FUNCTION Node(_NodeID integer)
RETURNS text
LANGUAGE sql
AS $$
SELECT format('%s%s', NodeTypes.NodeType, Nodes.NodeID) FROM Nodes
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
WHERE Nodes.NodeID = $1
$$;
