CREATE OR REPLACE FUNCTION Data_Node(_NodeID integer)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_DataNodeID  integer;
_ArrayNodeID integer;
_PtrNodeID   integer;
_ProgramID   integer;
_LanguageID  integer;
_OK          boolean;
BEGIN

_DataNodeID := Get_Single_Node(_NodeID, 'DATA');

IF _DataNodeID IS NOT NULL THEN
    RETURN _DataNodeID;
END IF;

SELECT
    Nodes.ProgramID,
    NodeTypes.LanguageID
INTO STRICT
    _ProgramID,
    _LanguageID
FROM Nodes
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
WHERE Nodes.NodeID = _NodeID;

_PtrNodeID := New_Node(
    _ProgramID      := _ProgramID,
    _NodeTypeID     := (SELECT NodeTypeID FROM NodeTypes WHERE LanguageID = _LanguageID AND NodeType = 'PTR'),
    _PrimitiveType  := 'integer',
    _PrimitiveValue := '1', -- PostgreSQL arrays start at 1
    _Walkable       := FALSE
);

_ArrayNodeID := New_Node(
    _ProgramID      := _ProgramID,
    _NodeTypeID     := (SELECT NodeTypeID FROM NodeTypes WHERE LanguageID = _LanguageID AND NodeType = 'ARRAY'),
    _PrimitiveType  := 'integer[]',
    _PrimitiveValue := '{0}',
    _Walkable       := FALSE
);

_DataNodeID := New_Node(
    _ProgramID      := _ProgramID,
    _NodeTypeID     := (SELECT NodeTypeID FROM NodeTypes WHERE LanguageID = _LanguageID AND NodeType = 'DATA'),
    _Walkable       := FALSE
);

PERFORM New_Edge(_ParentNodeID := _PtrNodeID,   _ChildNodeID := _DataNodeID);
PERFORM New_Edge(_ParentNodeID := _ArrayNodeID, _ChildNodeID := _DataNodeID);

PERFORM Set_Node_Value(_DataNodeID, 0::integer);

RETURN _DataNodeID;
END;
$$;
