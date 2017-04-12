CREATE OR REPLACE FUNCTION "EVAL"."LEAVE_RETURN_STATEMENT"(_NodeID integer) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_ReturnValueNodeID         integer;
_ProgramID                 integer;
_CallNodeID                integer;
_RetNodeID                 integer;
_FunctionDeclarationNodeID integer;
_ProgramNodeID             integer;
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

_FunctionDeclarationNodeID := Find_Node(
    _NodeID  := _NodeID,
    _Descend := TRUE,
    _Strict  := FALSE,
    _Path    := '-> FUNCTION_DECLARATION'
);
IF _FunctionDeclarationNodeID IS NOT NULL THEN
    _RetNodeID  := Find_Node(_NodeID := _FunctionDeclarationNodeID, _Descend := FALSE, _Strict := TRUE, _Path := '<- RET');

    SELECT      CALL.NodeID
    INTO STRICT _CallNodeID
    FROM (
        SELECT Edges.ParentNodeID AS NodeID
        FROM Edges
        WHERE Edges.ChildNodeID  = _RetNodeID
        AND   Edges.DeathPhaseID IS NULL
        ORDER BY Edges.EdgeID DESC
        LIMIT 1
    ) AS CALL
    INNER JOIN Nodes     ON Nodes.NodeID         = CALL.NodeID
    INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
    WHERE Nodes.DeathPhaseID IS NULL
    AND   NodeTypes.NodeType = 'CALL';

    PERFORM Set_Program_Node(_ProgramID := _ProgramID, _GotoNodeID := _RetNodeID, _CurrentNodeID := _NodeID);
    UPDATE Nodes SET Visited = Visited + 1 WHERE NodeID = _RetNodeID RETURNING TRUE INTO STRICT _OK;
    PERFORM Copy_Node(_FromNodeID := _ReturnValueNodeID, _ToNodeID := _CallNodeID);
ELSE
    -- Returning from program
    _ProgramNodeID := Get_Program_Node(_ProgramID := _ProgramID);
    PERFORM Set_Program_Node(_ProgramID := _ProgramID, _GotoNodeID := _ProgramNodeID, _CurrentNodeID := _NodeID);
    PERFORM Copy_Node(_FromNodeID := _ReturnValueNodeID, _ToNodeID := _ProgramNodeID);
END IF;

RETURN;
END;
$$;
