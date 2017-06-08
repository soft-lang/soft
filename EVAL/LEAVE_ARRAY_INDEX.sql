CREATE OR REPLACE FUNCTION "EVAL"."LEAVE_ARRAY_INDEX"(_NodeID integer) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_ParentNodes        integer[];
_ArrayNodeID        integer;
_IndexNodeID        integer;
_ArrayIndex         integer;
_ArrayElements      integer[];
_ClonedNodeID       integer;
_ZeroBasedNumbering boolean;
_OK                 boolean;
BEGIN

SELECT
    Languages.ZeroBasedNumbering
INTO STRICT
    _ZeroBasedNumbering
FROM Nodes
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
INNER JOIN Languages ON Languages.LanguageID = NodeTypes.LanguageID
WHERE NodeID = _NodeID;

SELECT array_agg(ParentNodeID ORDER BY EdgeID)
INTO STRICT _ParentNodes
FROM Edges
WHERE ChildNodeID = _NodeID
AND DeathPhaseID IS NULL;

IF array_length(_ParentNodes, 1) IS DISTINCT FROM 2 THEN
    RAISE EXCEPTION 'Array index does not have exactly two parent nodes NodeID % ParentNodes %', _NodeID, _ParentNodes;
END IF;

_ArrayNodeID := _ParentNodes[1];
_IndexNodeID := _ParentNodes[2];

SELECT array_agg(ParentNodeID ORDER BY EdgeID)
INTO STRICT _ArrayElements
FROM Edges
WHERE ChildNodeID = _ArrayNodeID
AND DeathPhaseID IS NULL;

IF Primitive_Type(_IndexNodeID) IS DISTINCT FROM 'integer'::regtype THEN
    RAISE EXCEPTION 'Array index node % is not an integer value but of type "%"', _NodeID, Primitive_Type(_IndexNodeID);
END IF;

_ArrayIndex := Primitive_Value(_IndexNodeID)::integer;

IF _ZeroBasedNumbering THEN
	_ArrayIndex := _ArrayIndex + 1;
END IF;

IF (_ArrayIndex BETWEEN 1 AND array_length(_ArrayElements,1)) IS NOT TRUE THEN
	RAISE EXCEPTION 'Array index % is out of bounds', _ArrayIndex;
END IF;

PERFORM Set_Reference_Node(_ReferenceNodeID := _ArrayElements[_ArrayIndex], _NodeID := _NodeID);

RETURN;
END;
$$;
