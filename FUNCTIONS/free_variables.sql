CREATE OR REPLACE FUNCTION soft.Free_Variables()
RETURNS boolean
LANGUAGE plpgsql
SET search_path TO soft, public, pg_temp
AS $$
DECLARE
_VariableNodeID integer;
_LastEdgeID integer;
_FreeNodeID integer;
_ChildNodeID integer;
_ParentNodeID integer;
_OK boolean;
_Visited integer;
BEGIN

FOR _VariableNodeID, _Visited IN
SELECT NodeID, Visited FROM Nodes
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
WHERE NodeTypes.NodeType = 'VARIABLE'
ORDER BY NodeID
LOOP
    _LastEdgeID := Find_Last_Edge(_VariableNodeID);
    SELECT New_Node(NodeTypeID) INTO STRICT _FreeNodeID FROM NodeTypes WHERE NodeType = 'FREE_STATEMENT';
    UPDATE Nodes SET Visited = _Visited WHERE NodeID = _FreeNodeID RETURNING TRUE INTO STRICT _OK;
    SELECT ParentNodeID INTO STRICT _ParentNodeID FROM Edges WHERE EdgeID = _LastEdgeID;
    UPDATE Edges SET ParentNodeID = _FreeNodeID WHERE EdgeID = _LastEdgeID RETURNING TRUE INTO STRICT _OK;
    INSERT INTO Edges (ParentNodeID, ChildNodeID) VALUES (_ParentNodeID, _FreeNodeID) RETURNING TRUE INTO STRICT _OK;
    INSERT INTO Edges (ParentNodeID, ChildNodeID) VALUES (_VariableNodeID, _FreeNodeID) RETURNING TRUE INTO STRICT _OK;
    RAISE NOTICE 'FREE_STATEMENT _VariableNodeID % _FreeNodeID % _ChildNodeID %', _VariableNodeID, _FreeNodeID, _ChildNodeID;
END LOOP;

RETURN TRUE;
END;
$$;
