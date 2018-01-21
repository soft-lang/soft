CREATE OR REPLACE FUNCTION Heap_Integer_Array(_NodeID integer)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_IntegerNodeID integer;
_DataNodeID    integer;
_ProgramID     integer;
_LanguageID    integer;
_OK            boolean;
BEGIN

-- Cannot use Dereference() since we don't want to resolve recursively, but get the very first
SELECT ReferenceNodeID INTO STRICT _DataNodeID FROM Nodes WHERE NodeID = _NodeID;

IF _DataNodeID <> _NodeID THEN
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

_IntegerNodeID := New_Node(
    _ProgramID      := _ProgramID,
    _NodeTypeID     := (SELECT NodeTypeID FROM NodeTypes WHERE LanguageID = _LanguageID AND NodeType = 'INTEGER'),
    _PrimitiveType  := 'integer',
    _PrimitiveValue := '0'
);

_DataNodeID := New_Node(
    _ProgramID      := _ProgramID,
    _NodeTypeID     := (SELECT NodeTypeID FROM NodeTypes WHERE LanguageID = _LanguageID AND NodeType = 'DATA')
);

-- Set the one and only data nodes reference to the first initial integer value
UPDATE Nodes SET ReferenceNodeID = _IntegerNodeID
WHERE NodeID = _DataNodeID
AND DeathPhaseID IS NULL
RETURNING TRUE INTO STRICT _OK;

-- Set all BF nodes to reference the one and only data node
UPDATE Nodes SET
    ReferenceNodeID = _DataNodeID,
    PrimitiveType   = NULL,
    PrimitiveValue  = NULL
WHERE ProgramID = _ProgramID
AND NodeID NOT IN (_IntegerNodeID, _DataNodeID)
AND DeathPhaseID IS NULL;

RETURN _DataNodeID;
END;
$$;
