CREATE OR REPLACE FUNCTION Get_LanguageID(_NodeID integer)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_LanguageID integer;
BEGIN
SELECT NodeTypes.LanguageID
INTO STRICT     _LanguageID
FROM Nodes
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
WHERE Nodes.NodeID = _NodeID;

RETURN _LanguageID;
END;
$$;
