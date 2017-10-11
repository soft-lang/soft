CREATE OR REPLACE FUNCTION Node(_NodeID integer, _Short boolean DEFAULT FALSE)
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
_ClonedFromNodeID integer;
BEGIN

SELECT
    NodeTypes.NodeType,
    Nodes.ReferenceNodeID,
    Nodes.PrimitiveValue,
    COALESCE(Nodes.ClonedFromNodeID,Nodes.NodeID)
INTO STRICT
    _NodeType,
    _ReferenceNodeID,
    _PrimitiveValue,
    _ClonedFromNodeID
FROM Nodes
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
WHERE Nodes.NodeID = _NodeID;

SELECT ROW_NUMBER INTO STRICT _Rank
FROM (
    SELECT NodeID, ROW_NUMBER() OVER () FROM (
        SELECT NodeID FROM Nodes WHERE NodeTypeID = (SELECT NodeTypeID FROM Nodes WHERE NodeID = _ClonedFromNodeID) ORDER BY NodeID
    ) AS X
) AS Y
WHERE NodeID = _ClonedFromNodeID;

_Label := format('%s%s',_NodeType,_Rank);

IF _ReferenceNodeID IS NOT NULL THEN
    _Label := _Label || '->' || Node(_ReferenceNodeID);
ELSIF _PrimitiveValue IS NOT NULL AND NOT _Short THEN
    _Label := _Label || '=' || _PrimitiveValue;
END IF;

RETURN _Label;
END;
$$;
