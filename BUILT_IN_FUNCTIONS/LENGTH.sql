CREATE OR REPLACE FUNCTION "BUILT_IN_FUNCTIONS"."LENGTH"(_NodeID integer) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_ParentNodes   integer[];
_ParentNodeID  integer;
_ArrayElements integer[];
_NodeType      text;
_OK            boolean;
BEGIN

_ParentNodes := Call_Args(_NodeID);

IF array_length(_ParentNodes, 1) IS DISTINCT FROM 1 THEN
    PERFORM Error(
        _NodeID    := _NodeID,
        _ErrorType := 'WRONG_NUMBER_OF_ARGUMENTS',
        _ErrorInfo := hstore(ARRAY[
            ['Got', array_length(_ParentNodes, 1)::text],
            ['Want', '1']
        ])
    );
    RETURN;
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
    PERFORM Error(
        _NodeID    := _NodeID,
        _ErrorType := 'ARGUMENT_NOT_SUPPORTED',
        _ErrorInfo := hstore(ARRAY[
            ['FunctionName', BuiltIn(_NodeID, 'LENGTH')],
            ['ArgumentType', Translate(_NodeID, Primitive_Type(_ParentNodeID)::text)]
        ])
    );
    RETURN;
END IF;

RETURN;
END;
$$;
