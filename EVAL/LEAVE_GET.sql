CREATE OR REPLACE FUNCTION "EVAL"."LEAVE_GET"(_NodeID integer)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_ClassNodeID    integer;
_ClassRefNodeID integer;
_Assignment     boolean;
_Call           boolean;
_ParentNodes    integer[];
_FieldNodeID    integer;
_OK             boolean;
BEGIN

SELECT array_agg(ParentNodeID ORDER BY EdgeID)
INTO STRICT _ParentNodes
FROM Edges
WHERE ChildNodeID = _NodeID
AND DeathPhaseID IS NULL;

IF array_length(_ParentNodes, 1) IS DISTINCT FROM 2 THEN
    RAISE EXCEPTION 'Get does not have exactly two parent nodes NodeID % ParentNodes %', _NodeID, _ParentNodes;
END IF;

IF Child(_NodeID, 'ASSIGNMENT') IS NOT NULL
AND Has_Child(_NodeID, _IsNthParent := 1)
THEN
    _Assignment := TRUE;
ELSE
    _Assignment := FALSE;
END IF;

_Call := Find_Node(
    _NodeID  := _NodeID,
    _Descend := FALSE,
    _Strict  := FALSE,
    _Path    := '-> CALL'
) IS NOT NULL;

_FieldNodeID := Get_Field(
    _NodeID     := Dereference(_ParentNodes[1]),
    _Name       := Primitive_Value(_ParentNodes[2])::name,
    _Assignment := _Assignment
);
IF _FieldNodeID IS NULL THEN
    RETURN;
END IF;

UPDATE Nodes SET
    PrimitiveType   = NULL,
    PrimitiveValue  = NULL,
    ReferenceNodeID = NULL
WHERE NodeID = _NodeID
RETURNING TRUE INTO STRICT _OK;

IF  NOT _Assignment
AND NOT _Call
THEN
    IF Primitive_Value(_FieldNodeID) IS NOT NULL THEN
        UPDATE Nodes SET
            PrimitiveType   = Primitive_Type(_FieldNodeID),
            PrimitiveValue  = Primitive_Value(_FieldNodeID)
        WHERE NodeID = _NodeID
        RETURNING TRUE INTO STRICT _OK;
    ELSE
        _ClassNodeID := Child(_FieldNodeID);
        _FieldNodeID := Clone(_FieldNodeID);
        SELECT New_Node(
            _ProgramID     := ProgramID,
            _NodeTypeID    := NodeTypeID,
            _NodeName      := NodeName,
            _EnvironmentID := (SELECT EnvironmentID FROM Nodes WHERE NodeID = _FieldNodeID)
        ) INTO _ClassRefNodeID
        FROM Nodes WHERE NodeID = _ClassNodeID;

        PERFORM Set_Reference_Node(_ReferenceNodeID := _ClassNodeID, _NodeID := _ClassRefNodeID);

        PERFORM New_Edge(
            _ParentNodeID := _FieldNodeID,
            _ChildNodeID  := _ClassRefNodeID
        );
        PERFORM Set_Reference_Node(_ReferenceNodeID := _FieldNodeID, _NodeID := _NodeID);
    END IF;
ELSE
    PERFORM Set_Reference_Node(_ReferenceNodeID := _FieldNodeID, _NodeID := _NodeID);
END IF;

RETURN;
END;
$$;
