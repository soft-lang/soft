CREATE OR REPLACE FUNCTION Language(_NodeID integer)
RETURNS Languages
LANGUAGE sql
AS $$
SELECT Languages.*
FROM Nodes
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
INNER JOIN Languages ON Languages.LanguageID = NodeTypes.LanguageID
WHERE NodeID = $1
$$;
