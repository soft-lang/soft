CREATE OR REPLACE FUNCTION Get_Field(_NodeID integer, _Name name, _Assignment boolean DEFAULT FALSE, _Strict boolean DEFAULT TRUE)
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

RAISE NOTICE 'Get_Field NodeID % NodeType % Name % Assignment %', _NodeID, _NodeType, _Name, _Assignment;

IF _NodeType = 'CLASS_DECLARATION'
AND Node_Name(_NodeID) IS NOT NULL
THEN
    _ClassNodeID := _NodeID;
ELSE
    PERFORM Error(
        _NodeID := _NodeID,
        _ErrorType := CASE WHEN _Assignment THEN 'ONLY_INSTANCES_HAVE_FIELDS' ELSE 'ONLY_INSTANCES_HAVE_PROPERTIES' END,
        _ErrorInfo := hstore(ARRAY[
            ['NodeType', _NodeType]
        ])
    );
    RETURN NULL;
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
    _SearchNodeID := Parent(Parent(_SearchNodeID, 'SUPERCLASS'));
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

IF _Assignment IS TRUE THEN
    -- We want to allow new field to be created if they do not exist
    -- when we are assigning.
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

IF _Strict THEN
    PERFORM Error(
        _NodeID    := _NodeID,
        _ErrorType := 'UNDEFINED_PROPERTY',
        _ErrorInfo := hstore(ARRAY[
            ['PropertyName', _Name]
        ])
    );
END IF;

RETURN NULL;
END;
$$;
