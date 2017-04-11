CREATE OR REPLACE FUNCTION "EVAL"."LEAVE_RETURN_STATEMENT"(_NodeID integer) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_ReturnValueNodeID         integer;
_ProgramID                 integer;
_CallNodeID                integer;
_RetNodeID                 integer;
_FunctionDeclarationNodeID integer;
_RetEdgeID                 integer;
_AllocaNodeID              integer;
_VariableNodeID            integer;
_OK                        boolean;
BEGIN

SELECT            ParentNodeID
INTO STRICT _ReturnValueNodeID
FROM Edges
WHERE ChildNodeID = _NodeID
AND DeathPhaseID IS NULL;

PERFORM Log(
    _NodeID   := _NodeID,
    _Severity := 'DEBUG3',
    _Message  := format('Return statement %s returning value from %s', Colorize(Node(_NodeID),'CYAN'), Colorize(Node(_ReturnValueNodeID),'MAGENTA'))
);

SELECT ProgramID INTO STRICT _ProgramID FROM Nodes WHERE NodeID = _NodeID;

_FunctionDeclarationNodeID := Find_Node(_NodeID := _NodeID,                    _Descend := TRUE,  _Strict := TRUE, _Path := '-> FUNCTION_DECLARATION');
_RetNodeID                 := Find_Node(_NodeID := _FunctionDeclarationNodeID, _Descend := FALSE, _Strict := TRUE, _Path := '<- RET');
_CallNodeID                := Find_Node(_NodeID := _RetNodeID,                 _Descend := FALSE, _Strict := TRUE, _Path := '<- CALL');
_AllocaNodeID              := Find_Node(_NodeID := _CallNodeID,                _Descend := FALSE, _Strict := TRUE, _Path := '<- FUNCTION_LABEL <- FUNCTION_DECLARATION <- ALLOCA');

PERFORM Set_Program_Node(_ProgramID := _ProgramID, _GotoNodeID := _CallNodeID, _CurrentNodeID := _NodeID);

UPDATE Nodes SET Visited = Visited + 1 WHERE NodeID = _CallNodeID RETURNING TRUE INTO STRICT _OK;
SELECT EdgeID INTO STRICT _RetEdgeID FROM Edges WHERE DeathPhaseID IS NULL AND ParentNodeID = _CallNodeID AND ChildNodeID = _RetNodeID;

PERFORM Copy_Node(_FromNodeID := _ReturnValueNodeID, _ToNodeID := _CallNodeID);
PERFORM Kill_Edge(_RetEdgeID);

FOR _VariableNodeID IN
SELECT ParentNodeID FROM Edges WHERE ChildNodeID = _AllocaNodeID ORDER BY EdgeID
LOOP
    PERFORM Pop_Node(_VariableNodeID);
END LOOP;

RETURN;
END;
$$;
