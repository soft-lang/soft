CREATE OR REPLACE FUNCTION "EVAL"."LEAVE_CALL"(_NodeID integer) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID                 integer;
_Visited                   integer;
_RetNodeID                 integer;
_FunctionDeclarationNodeID integer;
_RetEdgeID                 integer;
_AllocaNodeID              integer;
_VariableNodeID            integer;
_OK                        boolean;
BEGIN

SELECT ProgramID, Visited INTO STRICT _ProgramID, _Visited FROM Nodes WHERE NodeID = _NodeID;

SELECT
    Edges.EdgeID,
    Edges.ChildNodeID
INTO
    _RetEdgeID,
    _RetNodeID
FROM Edges
INNER JOIN Nodes     ON Nodes.NodeID         = Edges.ChildNodeID
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
WHERE Edges.ParentNodeID = _NodeID
AND   Edges.DeathPhaseID IS NULL
AND   Nodes.DeathPhaseID IS NULL
AND   Nodes.Visited      = _Visited
AND   NodeTypes.NodeType = 'RET'
ORDER BY Edges.EdgeID DESC
LIMIT 1;
IF NOT FOUND THEN
    _FunctionDeclarationNodeID := Find_Node(_NodeID := _NodeID, _Descend := FALSE, _Strict := TRUE, _Path := '<- FUNCTION_LABEL <- FUNCTION_DECLARATION');
    _RetNodeID                 := Find_Node(_NodeID := _NodeID, _Descend := FALSE, _Strict := TRUE, _Path := '<- FUNCTION_LABEL <- FUNCTION_DECLARATION <- RET');
    PERFORM Log(
        _NodeID   := _NodeID,
        _Severity := 'DEBUG3',
        _Message  := format('Outgoing function call at %s to %s', Colorize(Node(_NodeID),'CYAN'), Colorize(Node(_FunctionDeclarationNodeID),'MAGENTA'))
    );
    UPDATE Programs SET NodeID = _FunctionDeclarationNodeID WHERE ProgramID = _ProgramID AND NodeID = _NodeID RETURNING TRUE INTO STRICT _OK;
    PERFORM New_Edge(
        _ProgramID    := _ProgramID,
        _ParentNodeID := _NodeID,
        _ChildNodeID  := _RetNodeID
    );
    UPDATE Nodes SET Visited = Visited + 1 WHERE NodeID = _FunctionDeclarationNodeID RETURNING TRUE INTO STRICT _OK;
--    UPDATE Nodes SET Visited = Visited - 1 WHERE NodeID = _NodeID                    RETURNING TRUE INTO STRICT _OK;
ELSE
    PERFORM Log(
        _NodeID   := _NodeID,
        _Severity := 'DEBUG3',
        _Message  := format('Returning function call at %s', Colorize(Node(_NodeID),'CYAN'))
    );
--    UPDATE Nodes SET Visited = Visited + 1 WHERE NodeID = _NodeID RETURNING TRUE INTO STRICT _OK;
--    SELECT EdgeID INTO STRICT _RetEdgeID FROM Edges WHERE DeathPhaseID IS NULL AND ParentNodeID = _NodeID AND ChildNodeID = _RetNodeID;
--    _FunctionDeclarationNodeID := Find_Node(_NodeID := _NodeID, _Descend := FALSE, _Strict := TRUE, _Path := '-> RET -> FUNCTION_DECLARATION');
    PERFORM Kill_Edge(_RetEdgeID);
--    IF Find_Node(_NodeID := _RetNodeID, _Descend := FALSE, _Strict := FALSE, _Path := '<- RET') IS NOT NULL THEN
--        PERFORM Pop_Node(_RetNodeID);
--    END IF;
    _AllocaNodeID := Find_Node(_NodeID := _NodeID, _Descend := FALSE, _Strict := TRUE, _Path := '<- FUNCTION_LABEL <- FUNCTION_DECLARATION <- ALLOCA');
    FOR _VariableNodeID IN
    SELECT ParentNodeID FROM Edges WHERE ChildNodeID = _AllocaNodeID ORDER BY EdgeID
    LOOP
        PERFORM Pop_Node(_VariableNodeID);
    END LOOP;
END IF;

RETURN;
END;
$$;
