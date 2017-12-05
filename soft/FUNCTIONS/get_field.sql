CREATE OR REPLACE FUNCTION Get_Field(_NodeID integer, _Name name, _CreateIfNotExists boolean DEFAULT FALSE)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_ClassNodeID      integer;
_NodeType         text;
_ParentNodeIDs    integer[];
_FieldNodeID      integer;
_SuperClassNodeID integer;
_SearchNodeID     integer;
BEGIN

_NodeType := Node_Type(_NodeID);

IF _NodeType = 'CLASS_DECLARATION' THEN
    _ClassNodeID := _NodeID;
ELSE
    RAISE EXCEPTION 'Cannot get field from NodeID % since it is of unsupported NodeType %', _NodeID, _NodeType;
END IF;

IF NULLIF(_Name,'') IS NULL THEN
    RAISE EXCEPTION 'Field cannot be NULL nor empty string. NodeID % Name %', _NodeID, _Name;
END IF;

_SearchNodeID := _NodeID;
LOOP
    _FieldNodeID := Find_Node(
        _NodeID  := _SearchNodeID,
        _Descend := FALSE,
        _Strict  := FALSE,
        _Names   := ARRAY[_Name],
        _Paths   := ARRAY[
            '<- FUNCTION_DECLARATION[1]',
            '<- VARIABLE[1]'
        ]
    );
    IF _FieldNodeID IS NOT NULL THEN
        EXIT;
    END IF;
    _SearchNodeID := Parent(Parent(_SearchNodeID, 'SUPER_CLASS'));
    IF _SearchNodeID IS NULL THEN
        EXIT;
    END IF;
END LOOP;

IF _FieldNodeID IS NOT NULL THEN
    PERFORM Log(
        _NodeID   := _NodeID,
        _Severity := 'DEBUG5',
        _Message  := format('Resolved field %s to %s', Colorize(_Name, 'GREEN'), Node(_FieldNodeID))
    );
    RETURN _FieldNodeID;
END IF;

IF _CreateIfNotExists IS TRUE THEN
    SELECT New_Node(
        _ProgramID      := ProgramID,
        _NodeTypeID     := (SELECT NodeTypeID FROM NodeTypes WHERE NodeType = 'VARIABLE'),
        _NodeName       := _Name,
        _Walkable       := FALSE,
        _EnvironmentID  := EnvironmentID
    ) INTO STRICT _FieldNodeID
    FROM Nodes
    WHERE NodeID = _NodeID;

    PERFORM New_Edge(
        _ParentNodeID     := _FieldNodeID,
        _ChildNodeID      := _NodeID,
        _EnvironmentID    := EnvironmentID
    ) FROM Nodes
    WHERE NodeID = _NodeID;

    RETURN _FieldNodeID;
END IF;
RAISE DEBUG 'No such field % in NodeID %', _Name, _NodeID;
RETURN NULL;
END;
$$;
