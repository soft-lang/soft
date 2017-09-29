CREATE OR REPLACE FUNCTION Get_Node_Label(_NodeID integer)
RETURNS text
LANGUAGE plpgsql
STRICT
AS $$
DECLARE
_Rank integer;
_NodeType text;
_ReferenceNodeID integer;
_PrimitiveValue text;
_Label text;
BEGIN

SELECT
	NodeTypes.NodeType,
	Nodes.ReferenceNodeID,
	Nodes.PrimitiveValue
INTO STRICT
	_NodeType,
	_ReferenceNodeID,
	_PrimitiveValue
FROM Nodes
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
WHERE Nodes.NodeID = _NodeID;

SELECT ROW_NUMBER INTO STRICT _Rank
FROM (
	SELECT NodeID, ROW_NUMBER() OVER () FROM (
		SELECT NodeID FROM Nodes WHERE NodeTypeID = (SELECT NodeTypeID FROM Nodes WHERE NodeID = _NodeID) ORDER BY NodeID
	) AS X
) AS Y
WHERE NodeID = _NodeID;

_Label := format('%s%s',_NodeType,_Rank);

IF _ReferenceNodeID IS NOT NULL THEN
	_Label := _Label || '->' || Get_Node_Label(_ReferenceNodeID);
ELSIF _PrimitiveValue IS NOT NULL THEN
	_Label := _Label || '=' || _PrimitiveValue;
END IF;

RETURN _Label;
END;
$$;