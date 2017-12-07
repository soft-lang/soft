CREATE OR REPLACE FUNCTION "BUILT_IN_FUNCTIONS"."LAST"(_NodeID integer) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_ParentNodes   integer[];
_ParentNodeID  integer;
_ArrayElements integer[];
_ClonedNodeID  integer;
_OK            boolean;
BEGIN

_ParentNodes := Call_Args(_NodeID);

IF array_length(_ParentNodes, 1) IS DISTINCT FROM 1 THEN
    RAISE EXCEPTION 'last() takes exactly one array as argument';
END IF;

_ParentNodeID := Dereference(_ParentNodes[1]);

IF Node_Type(_ParentNodeID) <> 'ARRAY' THEN
    PERFORM Error(
        _NodeID    := _NodeID,
        _ErrorType := 'UNEXPECTED_ARGUMENT',
        _ErrorInfo := hstore(ARRAY[
            ['FunctionName', BuiltIn(_NodeID, 'LAST')],
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
    _ClonedNodeID := Clone_Node(_ArrayElements[array_length(_ArrayElements,1)]);
    PERFORM Set_Reference_Node(_ReferenceNodeID := _ClonedNodeID, _NodeID := _NodeID);
END IF;

RETURN;
END;
$$;
