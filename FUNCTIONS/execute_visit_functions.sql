CREATE OR REPLACE FUNCTION soft.Execute_Visit_Functions(_ProgramID integer)
RETURNS boolean
LANGUAGE plpgsql
SET search_path TO soft, public, pg_temp
AS $$
DECLARE
_NodeID integer;
_ValueType regtype;
_ParentNodeID integer;
_ChildNodeID integer;
_OK boolean;
_Visited integer;
_NodeType text;
_PreVisitFunction text;
_PostVisitFunction text;
BEGIN

SELECT NodeID INTO STRICT _NodeID FROM Programs WHERE ProgramID = _ProgramID;

SELECT Nodes.ValueType, Nodes.Visited INTO STRICT _ValueType, _Visited FROM Nodes
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
WHERE NodeID = _NodeID;

SELECT Edges.ParentNodeID, NodeTypes.NodeType,  NodeTypes.PreVisitFunction
INTO        _ParentNodeID,          _NodeType,           _PreVisitFunction
FROM Edges
INNER JOIN Nodes     ON Nodes.NodeID         = Edges.ParentNodeID
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
WHERE Edges.ChildNodeID = _NodeID
AND Nodes.Visited < _Visited
ORDER BY Edges.EdgeID
LIMIT 1;
IF FOUND THEN
    UPDATE Programs SET NodeID = _ParentNodeID WHERE ProgramID = _ProgramID RETURNING TRUE INTO STRICT _OK;
    UPDATE Nodes SET Visited = Visited + 1 WHERE NodeID = _ParentNodeID RETURNING TRUE INTO STRICT _OK;
    IF _PreVisitFunction IS NOT NULL THEN
        EXECUTE format('SELECT soft.%I()',_PreVisitFunction);
    END IF;
    RETURN TRUE;
END IF;

SELECT Edges.ChildNodeID, NodeTypes.PostVisitFunction
INTO        _ChildNodeID,          _PostVisitFunction
FROM Edges
INNER JOIN Nodes     ON Nodes.NodeID         = Edges.ParentNodeID
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
WHERE Edges.ParentNodeID = _NodeID
ORDER BY EdgeID
LIMIT 1;
IF FOUND THEN
    IF _PostVisitFunction IS NOT NULL THEN
        EXECUTE format('SELECT soft.%I()',_PostVisitFunction);
    END IF;
    UPDATE Programs SET NodeID = _ChildNodeID WHERE ProgramID = _ProgramID RETURNING TRUE INTO STRICT _OK;
    RETURN TRUE;
END IF;

RETURN FALSE;
END;
$$;
