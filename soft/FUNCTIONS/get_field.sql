CREATE OR REPLACE FUNCTION Get_Field(_InstanceNodeID integer, _Identifier text, _CreateIfNotExists boolean DEFAULT FALSE)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_ParentNodeIDs  integer[];
_VariableNodeID integer;
_FieldNodeID    integer;
BEGIN

IF Node_Type(_InstanceNodeID) IS DISTINCT FROM 'CLASS_DECLARATION' THEN
    RAISE EXCEPTION 'NodeID % is not a CLASS_DECLARATION', _InstanceNodeID;
END IF;
SELECT array_agg(ParentNodeID ORDER BY ParentNodeID)
INTO _ParentNodeIDs
FROM Edges
WHERE ChildNodeID = _InstanceNodeID
AND   DeathPhaseID IS NULL;
IF array_length(_ParentNodeIDs,1) % 2 <> 0 THEN
    RAISE EXCEPTION 'Uneven parent nodes % to class NodeID %', _ParentNodeIDs, _InstanceNodeID;
END IF;
FOR _i IN 1..array_length(_ParentNodeIDs,1)/2 LOOP
    _VariableNodeID := _ParentNodeIDs[_i*2-1];
    _FieldNodeID    := _ParentNodeIDs[_i*2];
    IF Node_Type(_VariableNodeID) IS DISTINCT FROM 'VARIABLE' THEN
        RAISE EXCEPTION 'Parent to class % is not VARIABLE but %', _InstanceNodeID, Node_Type(_VariableNodeID);
    END IF;
    IF Primitive_Value(_VariableNodeID) = _Identifier THEN
        PERFORM Log(
            _NodeID   := _InstanceNodeID,
            _Severity := 'DEBUG5',
            _Message  := format('Resolved field %s to %s', Colorize(_Identifier, 'GREEN'), Node(_FieldNodeID))
        );
        RETURN _FieldNodeID;
    END IF;
END LOOP;
IF _CreateIfNotExists IS TRUE THEN
    SELECT New_Node(
        _ProgramID      := ProgramID,
        _NodeTypeID     := (SELECT NodeTypeID FROM NodeTypes WHERE NodeType = 'VARIABLE'),
        _PrimitiveType  := 'text'::regtype,
        _PrimitiveValue := _Identifier,
        _Walkable       := FALSE,
        _EnvironmentID  := EnvironmentID
    ) INTO STRICT _VariableNodeID
    FROM Nodes
    WHERE NodeID = _InstanceNodeID;

    PERFORM New_Edge(
        _ParentNodeID     := _VariableNodeID,
        _ChildNodeID      := _InstanceNodeID,
        _EnvironmentID    := EnvironmentID
    ) FROM Nodes
    WHERE NodeID = _InstanceNodeID;

    SELECT New_Node(
        _ProgramID     := ProgramID,
        _NodeTypeID    := (SELECT NodeTypeID FROM NodeTypes WHERE NodeType = 'VALUE'),
        _Walkable      := FALSE,
        _EnvironmentID := EnvironmentID
    ) INTO STRICT _FieldNodeID
    FROM Nodes
    WHERE NodeID = _InstanceNodeID;

    PERFORM New_Edge(
        _ParentNodeID     := _FieldNodeID,
        _ChildNodeID      := _InstanceNodeID,
        _EnvironmentID    := EnvironmentID
    ) FROM Nodes
    WHERE NodeID = _InstanceNodeID;

    RETURN _FieldNodeID;
END IF;
RAISE EXCEPTION 'No such field % in NodeID %', _Identifier, _InstanceNodeID;
END;
$$;
