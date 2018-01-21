CREATE OR REPLACE FUNCTION "EVAL"."ENTER_INC_PTR"(_NodeID integer)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_DataNodeID    integer;
_ProgramID     integer;
_LanguageID    integer;
_IntegerNodeID integer;
_OK            boolean;
BEGIN

_DataNodeID := Heap_Integer_Array(_NodeID);

SELECT
    Nodes.ProgramID,
    NodeTypes.LanguageID
INTO STRICT
    _ProgramID,
    _LanguageID
FROM Nodes
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
WHERE Nodes.NodeID = _NodeID;

_IntegerNodeID := Child(Dereference(_DataNodeID), 'INTEGER');
IF _IntegerNodeID IS NULL THEN
    _IntegerNodeID := New_Node(
        _ProgramID      := _ProgramID,
        _NodeTypeID     := (SELECT NodeTypeID FROM NodeTypes WHERE LanguageID = _LanguageID AND NodeType = 'INTEGER'),
        _PrimitiveType  := 'integer',
        _PrimitiveValue := '0'
    );
    PERFORM New_Edge(_ParentNodeID := Dereference(_DataNodeID), _ChildNodeID := _IntegerNodeID);
END IF;

RAISE NOTICE 'DataNodeID % IntegerNodeID % DataNodePrimitiveValue %', _DataNodeID, _IntegerNodeID, (SELECT PrimitiveValue FROM Nodes WHERE NodeID = _DataNodeID);
UPDATE Nodes SET ReferenceNodeID = _IntegerNodeID WHERE NodeID = _DataNodeID RETURNING TRUE INTO STRICT _OK;

RETURN;
END;
$$;
