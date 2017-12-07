CREATE OR REPLACE FUNCTION "BUILT_IN_FUNCTIONS"."FIRST"(_NodeID integer) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_ParentNodes   integer[];
_ParentNodeID  integer;
_ArrayElements integer[];
_ClonedNodeID  integer;
_OK            boolean;
BEGIN

SELECT array_agg(ParentNodeID ORDER BY EdgeID)
INTO STRICT _ParentNodes
FROM Edges
WHERE ChildNodeID = _NodeID
AND DeathPhaseID IS NULL;

IF array_length(_ParentNodes, 1) IS DISTINCT FROM 2 THEN
    RAISE EXCEPTION 'first() takes exactly one array as argument';
END IF;

_ParentNodeID := Dereference(_ParentNodes[2]);

IF Node_Type(_ParentNodeID) <> 'ARRAY' THEN
    PERFORM Error(
        _NodeID    := _NodeID,
        _ErrorType := 'UNEXPECTED_ARGUMENT',
        _ErrorInfo := hstore(ARRAY[
            ['FunctionName', BuiltIn(_NodeID, 'FIRST')],
            ['Want',         Translate(_NodeID, 'ARRAY')],
            ['Got',          Translate(_NodeID, Node_Type(_ParentNodeID))]
        ])
    );
    RETURN;
END IF;

SELECT
    array_agg(ParentNodeID ORDER BY EdgeID)
INTO STRICT
    _ArrayElements
FROM Edges
WHERE ChildNodeID = _ParentNodeID
AND DeathPhaseID IS NULL;

IF _ArrayElements IS NULL THEN
    PERFORM Set_Node_Value(_NodeID, 'nil'::regtype, 'nil');
ELSE
    _ClonedNodeID := Clone_Node(_ArrayElements[1]);
    PERFORM Set_Reference_Node(_ReferenceNodeID := _ClonedNodeID, _NodeID := _NodeID);
END IF;

RETURN;
END;
$$;
