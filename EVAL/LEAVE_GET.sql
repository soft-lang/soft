CREATE OR REPLACE FUNCTION "EVAL"."LEAVE_GET"(_NodeID integer)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_Assignment  boolean;
_Call        boolean;
_ParentNodes integer[];
_FieldNodeID integer;
_OK          boolean;
BEGIN

SELECT array_agg(ParentNodeID ORDER BY EdgeID)
INTO STRICT _ParentNodes
FROM Edges
WHERE ChildNodeID = _NodeID
AND DeathPhaseID IS NULL;

IF array_length(_ParentNodes, 1) IS DISTINCT FROM 2 THEN
    RAISE EXCEPTION 'Get does not have exactly two parent nodes NodeID % ParentNodes %', _NodeID, _ParentNodes;
END IF;

_Assignment := Find_Node(
    _NodeID  := _NodeID,
    _Descend := FALSE,
    _Strict  := FALSE,
    _Path    := '-> ASSIGNMENT'
) IS NOT NULL;

_Call := Find_Node(
    _NodeID  := _NodeID,
    _Descend := FALSE,
    _Strict  := FALSE,
    _Path    := '-> CALL'
) IS NOT NULL;

_FieldNodeID := Get_Field(
    _NodeID            := Dereference(_ParentNodes[1]),
    _Name              := Primitive_Value(_ParentNodes[2])::name,
    _CreateIfNotExists := _Assignment
);

UPDATE Nodes SET
    PrimitiveType  = NULL,
    PrimitiveValue = NULL
WHERE NodeID = _NodeID
RETURNING TRUE INTO STRICT _OK;

IF  NOT _Assignment
AND NOT _Call
THEN
    RAISE NOTICE 'Cloning _FieldNodeID % since _Assignment % _Call %', _FieldNodeID, _Assignment, _Call;
    _FieldNodeID := Clone(_FieldNodeID);
END IF;

PERFORM Set_Reference_Node(_ReferenceNodeID := _FieldNodeID, _NodeID := _NodeID);

RETURN;
END;
$$;
