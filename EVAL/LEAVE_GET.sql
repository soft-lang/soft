CREATE OR REPLACE FUNCTION "EVAL"."LEAVE_GET"(_NodeID integer)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_CreateFieldIfNotExists boolean := FALSE;
_ParentNodes            integer[];
_FieldNodeID            integer;
_OK                     boolean;
BEGIN

IF Find_Node(
    _NodeID  := _NodeID,
    _Descend := FALSE,
    _Strict  := FALSE,
    _Path    := '-> ASSIGNMENT'
) IS NOT NULL THEN
    _CreateFieldIfNotExists := TRUE;
END IF;

SELECT array_agg(ParentNodeID ORDER BY EdgeID)
INTO STRICT _ParentNodes
FROM Edges
WHERE ChildNodeID = _NodeID
AND DeathPhaseID IS NULL;

IF array_length(_ParentNodes, 1) IS DISTINCT FROM 2 THEN
    RAISE EXCEPTION 'Get does not have exactly two parent nodes NodeID % ParentNodes %', _NodeID, _ParentNodes;
END IF;

_FieldNodeID := Get_Field(
    _NodeID            := Dereference(_ParentNodes[1]),
    _Name              := Primitive_Value(_ParentNodes[2])::name,
    _CreateIfNotExists := _CreateFieldIfNotExists
);

UPDATE Nodes SET
    PrimitiveType  = NULL,
    PrimitiveValue = NULL
WHERE NodeID = _NodeID
RETURNING TRUE INTO STRICT _OK;

PERFORM Set_Reference_Node(_ReferenceNodeID := _FieldNodeID, _NodeID := _NodeID);

RETURN;
END;
$$;
