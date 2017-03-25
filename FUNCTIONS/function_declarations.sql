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
    UPDATE Edges SET ParentNodeID = _FunctionNodeID WHERE ChildNodeID = _VariableNodeID RETURNING TRUE INTO STRICT _OK;
    RAISE NOTICE 'FUNCTION_DECLARATIONS _FunctionNodeID %', _FunctionNodeID;
END LOOP;

-- FOR _FunctionNodeID, _Visited IN
-- SELECT NodeID, Visited FROM Nodes
-- INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
-- WHERE NodeTypes.NodeType = 'FUNCTION_CALL'
-- ORDER BY NodeID
-- LOOP
--     _DeclarationNodeID := Find_Node(_FunctionNodeID, '<- VARIABLE <- FUNCTION_DECLARATION <- FUNCTION_PARAMS');
--     SELECT ParentNodeID INTO STRICT _ParamsNodeID FROM Edges WHERE ChildNodeID = _DeclarationNodeID ORDER BY EdgeID      LIMIT 1;
--     SELECT ParentNodeID INTO STRICT _ArgsNodeID   FROM Edges WHERE ChildNodeID = _FunctionNodeID    ORDER BY EdgeID DESC LIMIT 1;
-- 
-- 
--     SELECT ChildNodeID INTO STRICT _LetStatementNodeID FROM Edges WHERE ParentNodeID = _FunctionNodeID;
--     SELECT ParentNodeID INTO STRICT _VariableNodeID FROM Edges WHERE ChildNodeID = _LetStatementNodeID ORDER BY EdgeID LIMIT 1;
--     DELETE FROM Edges WHERE _LetStatementNodeID IN (ChildNodeID,ParentNodeID);
--     DELETE FROM Nodes WHERE NodeID = _LetStatementNodeID RETURNING TRUE INTO STRICT _OK;
--     UPDATE Edges SET ParentNodeID = _FunctionNodeID WHERE ChildNodeID = _VariableNodeID RETURNING TRUE INTO STRICT _OK;
--     RAISE NOTICE 'FUNCTION_DECLARATIONS _FunctionNodeID %', _FunctionNodeID;
-- END LOOP;

RETURN TRUE;
END;
$$;
