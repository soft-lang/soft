CREATE OR REPLACE FUNCTION "EVAL"."LEAVE_LENGTH_EXPRESSION"(_NodeID integer) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_ParentNodes   integer[];
_ParentNodeID  integer;
_ArrayElements integer[];
_NodeType      text;
_OK            boolean;
BEGIN

SELECT array_agg(ParentNodeID ORDER BY EdgeID)
INTO STRICT _ParentNodes
FROM Edges
WHERE ChildNodeID = _NodeID
AND DeathPhaseID IS NULL;

IF array_length(_ParentNodes, 1) IS DISTINCT FROM 1 THEN
    RAISE EXCEPTION 'Length does not have exactly one parent nodes NodeID % ParentNodes %', _NodeID, _ParentNodes;
END IF;

_ParentNodeID := Dereference(_ParentNodes[1]);

SELECT NodeTypes.NodeType INTO STRICT _NodeType
FROM Nodes
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
WHERE Nodes.NodeID = _ParentNodeID;

IF _NodeType = 'ARRAY' THEN
	SELECT array_agg(ParentNodeID ORDER BY EdgeID)
	INTO STRICT _ArrayElements
	FROM Edges
	WHERE ChildNodeID = _ParentNodeID
	AND DeathPhaseID IS NULL;
	UPDATE Nodes SET
		PrimitiveType  = 'integer'::regtype,
		PrimitiveValue = COALESCE(array_length(_ArrayElements,1),0)
	WHERE NodeID = _NodeID
	RETURNING TRUE INTO STRICT _OK;
ELSIF Primitive_Type(_ParentNodeID) = 'text'::regtype THEN
	UPDATE Nodes SET
		PrimitiveType  = 'integer'::regtype,
		PrimitiveValue = length(Primitive_Value(_ParentNodeID))
	WHERE NodeID = _NodeID
	RETURNING TRUE INTO STRICT _OK;
ELSE
	RAISE EXCEPTION 'Cannot compute length of type %', Primitive_Type(_ParentNodeID);
END IF;

RETURN;
END;
$$;
