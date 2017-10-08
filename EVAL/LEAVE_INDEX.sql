CREATE OR REPLACE FUNCTION "EVAL"."LEAVE_INDEX"(_NodeID integer)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_ParentNodes     integer[];
_ArrayHashNodeID integer;
_NodeType        text;
_IndexNodeID     integer;
_ArrayIndex      integer;
_HashKeyType     regtype;
_HashKeyValue    text;
_HashPairNodeID  integer;
_HashPairNodeIDs integer[];
_ArrayElements   integer[];
_ClonedNodeID    integer;
_OK              boolean;
BEGIN

SELECT array_agg(ParentNodeID ORDER BY EdgeID)
INTO STRICT _ParentNodes
FROM Edges
WHERE ChildNodeID = _NodeID
AND DeathPhaseID IS NULL;

IF array_length(_ParentNodes, 1) IS DISTINCT FROM 2 THEN
    RAISE EXCEPTION 'Index does not have exactly two parent nodes NodeID % ParentNodes %', _NodeID, _ParentNodes;
END IF;

_ArrayHashNodeID := Dereference(_ParentNodes[1]);
_IndexNodeID     := Dereference(_ParentNodes[2]);

SELECT NodeTypes.NodeType INTO STRICT _NodeType
FROM Nodes
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
WHERE Nodes.NodeID = _ArrayHashNodeID;

IF _NodeType = 'ARRAY' THEN
    SELECT array_agg(ParentNodeID ORDER BY EdgeID)
    INTO STRICT _ArrayElements
    FROM Edges
    WHERE ChildNodeID = _ArrayHashNodeID
    AND DeathPhaseID IS NULL;
    IF Primitive_Type(_IndexNodeID) IS DISTINCT FROM 'integer'::regtype THEN
        RAISE EXCEPTION 'Array index node % is not an integer value but of type "%"', _NodeID, Primitive_Type(_IndexNodeID);
    END IF;
    _ArrayIndex := Primitive_Value(_IndexNodeID)::integer;
    IF (Language(_NodeID)).ZeroBasedNumbering THEN
        _ArrayIndex := _ArrayIndex + 1;
    END IF;
    IF _ArrayIndex BETWEEN 1 AND array_length(_ArrayElements,1) THEN
        PERFORM Set_Reference_Node(_ReferenceNodeID := _ArrayElements[_ArrayIndex], _NodeID := _NodeID);
    ELSIF (Language(_NodeID)).ArrayOutOfBoundsError THEN
        RAISE EXCEPTION 'Array index % is out of bounds', _ArrayIndex;
    ELSE
        PERFORM Set_Node_Value(_NodeID, 'nil'::regtype, 'nil');
    END IF;
ELSIF _NodeType = 'HASH' THEN
    _HashKeyType  := Primitive_Type(_IndexNodeID);
    _HashKeyValue := Primitive_Value(_IndexNodeID);
    IF _HashKeyType IS NULL THEN
        RAISE EXCEPTION 'Unusable as hash key: %', Node_Type(_IndexNodeID);
    END IF;
    FOR _HashPairNodeID IN
    SELECT ParentNodeID
    FROM Edges
    WHERE ChildNodeID = _ArrayHashNodeID
    AND DeathPhaseID IS NULL
    ORDER BY EdgeID DESC
    LOOP
        SELECT array_agg(ParentNodeID ORDER BY EdgeID)
        INTO STRICT _HashPairNodeIDs
        FROM Edges
        WHERE ChildNodeID = _HashPairNodeID
        AND DeathPhaseID IS NULL;
        IF array_length(_HashPairNodeIDs, 1) IS DISTINCT FROM 2 THEN
            RAISE EXCEPTION 'HashPairNodeID % does not have exactly two parent nodes HashPairNodeIDs %', _HashPairNodeID, _HashPairNodeIDs;
        END IF;
        IF  Primitive_Type(_HashPairNodeIDs[1])  = _HashKeyType
        AND Primitive_Value(_HashPairNodeIDs[1]) = _HashKeyValue
        THEN
            PERFORM Set_Reference_Node(_ReferenceNodeID := _HashPairNodeIDs[2], _NodeID := _NodeID);
            RETURN;
        END IF;
    END LOOP;
    IF (Language(_NodeID)).MissingHashKeyError THEN
        RAISE EXCEPTION 'Hash key "%" of type "%" does not exist', _HashKeyValue, _HashKeyType;
    ELSE
        PERFORM Set_Node_Value(_NodeID, 'nil'::regtype, 'nil');
    END IF;
ELSE
    RAISE EXCEPTION 'Index does not work with NodeType %', _NodeType;
END IF;

RETURN;
END;
$$;
