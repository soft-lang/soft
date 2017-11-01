CREATE OR REPLACE FUNCTION Node(_NodeID integer, _Short boolean DEFAULT FALSE)
RETURNS text
LANGUAGE plpgsql
STRICT
AS $$
DECLARE
_NodeType         text;
_NodeTypeID       integer;
_ReferenceNodeID  integer;
_PrimitiveValue   text;
_Label            text;
_ClonedFromNodeID integer;
BEGIN

SELECT
    NodeTypeID,
    ReferenceNodeID,
    PrimitiveValue
INTO STRICT
    _NodeTypeID,
    _ReferenceNodeID,
    _PrimitiveValue
FROM Nodes
WHERE NodeID = _NodeID;

SELECT       NodeType
INTO STRICT _NodeType
FROM NodeTypes
WHERE NodeTypeID = _NodeTypeID;

_Label := format('%s%s',_NodeType,_NodeID);

IF _ReferenceNodeID IS NOT NULL THEN
    _Label := _Label || '->' || Node(_ReferenceNodeID);
ELSIF _PrimitiveValue IS NOT NULL AND NOT _Short THEN
    _Label := _Label || '=' || _PrimitiveValue;
END IF;

RETURN _Label;
END;
$$;
