CREATE OR REPLACE FUNCTION Serialize_Node(_NodeID integer)
RETURNS text
LANGUAGE sql
AS $$
SELECT replace(json_object(ARRAY[
    ['NodeID',           Nodes.NodeID::text],
    ['NodeType',         NodeTypes.NodeType],
    ['Walkable',         Nodes.Walkable::text],
    ['PrimitiveType',    Nodes.PrimitiveType::text],
    ['PrimitiveValue',   Nodes.PrimitiveValue],
    ['ReferenceNodeID',  Nodes.ReferenceNodeID::text],
    ['ClonedFromNodeID', Nodes.ClonedFromNodeID::text],
    ['ClonedRootNodeID', Nodes.ClonedRootNodeID::text]
])::text,'"','\"') FROM Nodes
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
WHERE Nodes.NodeID = $1
$$;
