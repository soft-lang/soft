CREATE OR REPLACE FUNCTION Change_Node_Type(_NodeID integer, _OldNodeType text, _NewNodeType text)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_NewNodeTypeID integer;
_OK            boolean;
BEGIN
SELECT NewNodeType.NodeTypeID
INTO STRICT    _NewNodeTypeID
FROM Nodes
INNER JOIN NodeTypes AS OldNodeType ON OldNodeType.NodeTypeID = Nodes.NodeTypeID
INNER JOIN NodeTypes AS NewNodeType ON NewNodeType.LanguageID = OldNodeType.LanguageID
WHERE Nodes.NodeID = _NodeID
AND OldNodeType.NodeType = _OldNodeType
AND NewNodeType.NodeType = _NewNodeType;

UPDATE Nodes SET NodeTypeID = _NewNodeTypeID
WHERE NodeID = _NodeID
RETURNING TRUE INTO STRICT _OK;

RETURN TRUE;
END;
$$;
