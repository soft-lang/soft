CREATE OR REPLACE FUNCTION Push_Node(_VariableNodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_NewNodeID integer;
_OK boolean;
BEGIN

SELECT New_Node(NodeTypeID) INTO STRICT _NewNodeID FROM NodeTypes WHERE NodeType = 'VARIABLE';

PERFORM Copy_Node(_VariableNodeID, _NewNodeID);

UPDATE Nodes SET
    ValueType    = NULL,
    NameValue    = NULL,
    BooleanValue = NULL,
    NumericValue = NULL,
    IntegerValue = NULL,
    TextValue    = NULL,
    Visited      = NULL
WHERE NodeID = _VariableNodeID
RETURNING TRUE INTO STRICT _OK;

IF EXISTS (SELECT 1 FROM Edges WHERE ChildNodeID = _VariableNodeID) THEN
    UPDATE Edges SET ChildNodeID = _NewNodeID WHERE ChildNodeID = _VariableNodeID RETURNING TRUE INTO STRICT _OK;
END IF;
INSERT INTO Edges (ParentNodeID, ChildNodeID) VALUES (_NewNodeID, _VariableNodeID) RETURNING TRUE INTO STRICT _OK;

RETURN TRUE;
END;
$$;
