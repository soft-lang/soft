CREATE OR REPLACE FUNCTION "EVAL"."ENTER_CALL"(_NodeID integer) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID                 integer;
_RetNodeID                 integer;
_FunctionDeclarationNodeID integer;
_RetEdgeID                 integer;
_AllocaNodeID              integer;
_VariableNodeID            integer;
_OK                        boolean;
BEGIN

SELECT ProgramID INTO STRICT _ProgramID FROM Nodes WHERE NodeID = _NodeID;

_RetNodeID := Find_Node(_NodeID := _NodeID, _Descend := FALSE, _Strict := FALSE, _Path := '-> RET');
IF _RetNodeID IS NULL THEN
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
    UPDATE Nodes SET Visited = Visited - 1 WHERE NodeID = _NodeID                    RETURNING TRUE INTO STRICT _OK;
ELSE
    UPDATE Nodes SET Visited = Visited + 1 WHERE NodeID = _NodeID                    RETURNING TRUE INTO STRICT _OK;
    SELECT EdgeID INTO STRICT _RetEdgeID FROM Edges WHERE DeathPhaseID IS NULL AND ParentNodeID = _NodeID AND ChildNodeID = _RetNodeID;
    _FunctionDeclarationNodeID := Find_Node(_NodeID := _NodeID, _Descend := FALSE, _Strict := TRUE, _Path := '-> RET -> FUNCTION_DECLARATION');

    PERFORM Log(
        _NodeID   := _NodeID,
        _Severity := 'DEBUG3',
        _Message  := format('Returning function call at %s', Colorize(Node(_NodeID),'CYAN'))
    );

    PERFORM Kill_Edge(_RetEdgeID);

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
