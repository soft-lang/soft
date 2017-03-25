CREATE OR REPLACE FUNCTION soft.Function_Declarations()
RETURNS boolean
LANGUAGE plpgsql
SET search_path TO soft, public, pg_temp
AS $$
DECLARE
_FunctionNodeID integer;
_LetStatementNodeID integer;
_VariableNodeID integer;
_OK boolean;
_Visited integer;
_DeclarationNodeID integer;
_ParamsNodeID integer;
_ArgsNodeID integer;
_NodeType text;
_AllocaNodeID integer;
_NodeID integer;
BEGIN

FOR _FunctionNodeID, _Visited IN
SELECT NodeID, Visited FROM Nodes
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
WHERE NodeTypes.NodeType = 'FUNCTION_DECLARATION'
ORDER BY NodeID
LOOP
    SELECT ChildNodeID INTO STRICT _LetStatementNodeID FROM Edges WHERE ParentNodeID = _FunctionNodeID;
    SELECT ParentNodeID INTO STRICT _VariableNodeID FROM Edges WHERE ChildNodeID = _LetStatementNodeID ORDER BY EdgeID LIMIT 1;
    DELETE FROM Edges WHERE _LetStatementNodeID IN (ChildNodeID,ParentNodeID);
    DELETE FROM Nodes WHERE NodeID = _LetStatementNodeID RETURNING TRUE INTO STRICT _OK;
    INSERT INTO Edges (ParentNodeID, ChildNodeID) VALUES (_FunctionNodeID, _VariableNodeID) RETURNING TRUE INTO STRICT _OK;
    UPDATE Nodes SET NodeTypeID = (SELECT NodeTypeID FROM NodeTypes WHERE NodeType = 'FUNCTION_LABEL') WHERE NodeID = _VariableNodeID RETURNING TRUE INTO STRICT _OK;
    RAISE NOTICE 'FUNCTION_DECLARATIONS _FunctionNodeID %', _FunctionNodeID;
END LOOP;

FOR _VariableNodeID, _NodeType IN
SELECT Nodes.NodeID, NodeTypes.NodeType FROM Nodes
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
WHERE NodeTypes.NodeType IN ('VARIABLE','IDENTIFIER')
ORDER BY Nodes.NodeID
LOOP
    IF _NodeType = 'IDENTIFIER' THEN
        UPDATE Nodes SET NodeTypeID = (SELECT NodeTypeID FROM NodeTypes WHERE NodeType = 'VARIABLE') WHERE NodeID = _VariableNodeID RETURNING TRUE INTO STRICT _OK;
    END IF;
    _NodeID := _VariableNodeID;
    LOOP
        SELECT AllocaNode.NodeID INTO _AllocaNodeID
        FROM Nodes AS Node1
        INNER JOIN Edges AS Edge1 ON Edge1.ParentNodeID = Node1.NodeID
        INNER JOIN Nodes AS Node2 ON Node2.NodeID = Edge1.ChildNodeID
        INNER JOIN Edges AS Edge2 ON Edge2.ChildNodeID = Node2.NodeID
        INNER JOIN Nodes AS AllocaNode ON AllocaNode.NodeID = Edge2.ParentNodeID
        WHERE Node1.NodeID = _NodeID
        AND AllocaNode.NodeTypeID  = (SELECT NodeTypeID FROM NodeTypes WHERE NodeType = 'ALLOCA')
        ORDER BY Edge1.EdgeID DESC
        LIMIT 1;
        IF FOUND THEN
            INSERT INTO Edges (ParentNodeID, ChildNodeID) VALUES (_VariableNodeID, _AllocaNodeID) RETURNING TRUE INTO STRICT _OK;
            EXIT;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM Edges WHERE ParentNodeID = _NodeID) THEN
            EXIT;
        END IF;
        SELECT ChildNodeID INTO STRICT _NodeID FROM Edges WHERE ParentNodeID = _NodeID ORDER BY EdgeID LIMIT 1;
    END LOOP;
END LOOP;

RETURN TRUE;
END;
$$;
