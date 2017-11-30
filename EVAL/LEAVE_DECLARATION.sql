CREATE OR REPLACE FUNCTION "EVAL"."LEAVE_DECLARATION"(_NodeID integer)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_ParentNodes  integer[];
_NumArgs      integer;
_ClonedNodeID integer;
_FromNodeID   integer;
_ToNodeID     integer;
_OK           boolean;
BEGIN

SELECT array_agg(ParentNodeID ORDER BY EdgeID)
INTO STRICT _ParentNodes
FROM Edges
WHERE ChildNodeID = _NodeID
AND DeathPhaseID IS NULL;

_NumArgs := array_length(_ParentNodes, 1);

IF _NumArgs = 1 THEN
    -- Variable declaration only, no assignment of value to it
    RETURN;
ELSIF _NumArgs IS DISTINCT FROM 2 THEN
    RAISE EXCEPTION 'Declaration does not have exactly two parent nodes NodeID % ParentNodes %', _NodeID, _ParentNodes;
END IF;

_ToNodeID   := _ParentNodes[1];
_FromNodeID := Dereference(_ParentNodes[2]);

PERFORM Copy_Node(
    _FromNodeID := _FromNodeID,
    _ToNodeID   := _ToNodeID
);

RETURN;
END;
$$;
