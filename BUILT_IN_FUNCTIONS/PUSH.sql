CREATE OR REPLACE FUNCTION "BUILT_IN_FUNCTIONS"."PUSH"(_NodeID integer) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_ParentNodes       integer[];
_ArrayElements     integer[];
_ArrayElementEdges integer[];
_ClonedNodeID      integer;
_PushNodeID        integer;
_OK                boolean;
BEGIN

_ParentNodes := Call_Args(_NodeID);

IF array_length(_ParentNodes, 1) IS DISTINCT FROM 2 THEN
    RAISE EXCEPTION 'push() takes exactly two arguments';
END IF;

IF Node_Type(Dereference(_ParentNodes[1])) <> 'ARRAY' THEN
    PERFORM Error(
        _NodeID    := _NodeID,
        _ErrorType := 'UNEXPECTED_ARGUMENT',
        _ErrorInfo := hstore(ARRAY[
            ['FunctionName', BuiltIn(_NodeID, 'PUSH')],
            ['Want',         Translate(_NodeID, 'ARRAY')],
            ['Got',          Translate(_NodeID, Node_Type(Dereference(_ParentNodes[1])))]
        ])
    );
END IF;

_ClonedNodeID := Clone_Node(Dereference(_ParentNodes[1]));
_PushNodeID   := Clone_Node(Dereference(_ParentNodes[2]));

PERFORM New_Edge(
    _ParentNodeID := _PushNodeID,
    _ChildNodeID  := _ClonedNodeID
);

PERFORM Set_Reference_Node(_ReferenceNodeID := _ClonedNodeID, _NodeID := _NodeID);

RETURN;
END;
$$;
