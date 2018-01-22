CREATE OR REPLACE FUNCTION "OPTIMIZE"."LEAVE_DEC_PTR"(_NodeID integer)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_LeftNodeID integer;
_ArgumentNodeID  integer;
_ProgramID  integer;
_LanguageID integer;
_OK         boolean;
BEGIN

_LeftNodeID := Left(_NodeID);

IF Node_Type(_LeftNodeID) IS DISTINCT FROM 'DEC_PTR' THEN
    RETURN;
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

_ArgumentNodeID := Parent(_LeftNodeID, 'ARGUMENT');
IF _ArgumentNodeID IS NULL THEN
    _ArgumentNodeID := New_Node(
        _ProgramID      := _ProgramID,
        _NodeTypeID     := (SELECT NodeTypeID FROM NodeTypes WHERE LanguageID = _LanguageID AND NodeType = 'ARGUMENT'),
        _PrimitiveType  := 'integer',
        _PrimitiveValue := '1',
        _Walkable       := FALSE
    );
    PERFORM New_Edge(_ParentNodeID := _ArgumentNodeID, _ChildNodeID := _LeftNodeID);
END IF;

UPDATE Nodes SET
    PrimitiveType  = 'integer'::regtype,
    PrimitiveValue = (PrimitiveValue::integer + 1)::text
WHERE NodeID = _ArgumentNodeID
RETURNING TRUE INTO STRICT _OK;

PERFORM Next_Node(_ProgramID);

PERFORM Kill_Edge(EdgeID)
FROM Edges
WHERE _NodeID IN (ParentNodeID, ChildNodeID)
AND DeathPhaseID IS NULL;

PERFORM Kill_Node(_NodeID);

RETURN;
END;
$$;
