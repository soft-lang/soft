CREATE OR REPLACE FUNCTION "EVAL"."LEAVE_RETURN_STATEMENT"(_NodeID integer) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_Visited                   integer;
_ReturnValueNodeID         integer;
_ProgramID                 integer;
_CallNodeID                integer;
_FunctionDeclarationNodeID integer;
_RetNodeID                 integer;
_ProgramNodeID             integer;
_OK                        boolean;
BEGIN

SELECT
    Nodes.Visited,
    Edges.ParentNodeID
INTO STRICT
    _Visited,
    _ReturnValueNodeID
FROM Edges
INNER JOIN Nodes ON Nodes.NodeID = Edges.ChildNodeID
WHERE Nodes.NodeID = _NodeID
AND Edges.DeathPhaseID IS NULL
AND Nodes.DeathPhaseID IS NULL;

PERFORM Log(
    _NodeID   := _NodeID,
    _Severity := 'DEBUG3',
    _Message  := format('Return statement %s returning value from %s', Colorize(Node(_NodeID),'CYAN'), Colorize(Node(_ReturnValueNodeID),'MAGENTA'))
);

SELECT ProgramID INTO STRICT _ProgramID FROM Nodes WHERE NodeID = _NodeID;

_FunctionDeclarationNodeID := Find_Node(
    _NodeID  := _NodeID,
    _Descend := TRUE,
    _Strict  := FALSE,
    _Path    := '-> FUNCTION_DECLARATION'
);
IF _FunctionDeclarationNodeID IS NOT NULL THEN
    _RetNodeID := Find_Node(
        _NodeID  := _FunctionDeclarationNodeID,
        _Descend := FALSE,
        _Strict  := TRUE,
        _Path    := '<- RET'
    );
    UPDATE Nodes SET Visited = _Visited WHERE NodeID = _RetNodeID RETURNING TRUE INTO STRICT _OK;
    PERFORM Copy_Node(_FromNodeID := _ReturnValueNodeID, _ToNodeID := _FunctionDeclarationNodeID);
    PERFORM Copy_Node(_FromNodeID := _ReturnValueNodeID, _ToNodeID := _NodeID);
    PERFORM Set_Program_Node(_ProgramID := _ProgramID, _GotoNodeID := _RetNodeID, _CurrentNodeID := _NodeID);
    PERFORM "EVAL"."ENTER_RET"(_RetNodeID);
    RETURN;
ELSE
    -- Returning from program
    _ProgramNodeID := Get_Program_Node(_ProgramID := _ProgramID);
    PERFORM Set_Program_Node(_ProgramID := _ProgramID, _GotoNodeID := _ProgramNodeID, _CurrentNodeID := _NodeID);
    PERFORM Copy_Node(_FromNodeID := _ReturnValueNodeID, _ToNodeID := _ProgramNodeID);
END IF;

RETURN;
END;
$$;
