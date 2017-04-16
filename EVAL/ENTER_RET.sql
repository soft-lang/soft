CREATE OR REPLACE FUNCTION "EVAL"."ENTER_RET"(_NodeID integer) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID                 integer;
_CallNodeID                integer;
_FunctionDeclarationNodeID integer;
_ProgramNodeID             integer;
_AllocaNodeID              integer;
_VariableNodeID            integer;
_OK                        boolean;
BEGIN

SELECT ProgramID INTO STRICT _ProgramID FROM Nodes WHERE NodeID = _NodeID;

_FunctionDeclarationNodeID := Find_Node(_NodeID := _NodeID, _Descend := FALSE, _Strict := FALSE, _Path := '-> FUNCTION_DECLARATION');
IF _FunctionDeclarationNodeID IS NOT NULL THEN
    _AllocaNodeID := Find_Node(_NodeID := _FunctionDeclarationNodeID, _Descend := FALSE, _Strict := TRUE, _Path := '<- ALLOCA');

    SELECT
        CALL.NodeID
    INTO STRICT
        _CallNodeID
    FROM (
        SELECT
            Edges.EdgeID,
            Edges.ParentNodeID AS NodeID
        FROM Edges
        WHERE Edges.ChildNodeID  = _NodeID
        AND   Edges.DeathPhaseID IS NULL
        ORDER BY Edges.EdgeID DESC
        LIMIT 1
    ) AS CALL
    INNER JOIN Nodes     ON Nodes.NodeID         = CALL.NodeID
    INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
    WHERE Nodes.DeathPhaseID IS NULL
    AND   NodeTypes.NodeType = 'CALL';

    PERFORM Copy_Node(_FromNodeID := _NodeID, _ToNodeID := _CallNodeID);

    UPDATE Nodes SET
        TerminalType  = NULL,
        TerminalValue = NULL
    WHERE NodeID = _NodeID
    AND DeathPhaseID IS NULL
    RETURNING TRUE INTO STRICT _OK;

    PERFORM Log(
        _NodeID   := _NodeID,
        _Severity := 'DEBUG3',
        _Message  := format('Returning function call at %s to %s', Colorize(Node(_NodeID),'CYAN'), Colorize(Node(_CallNodeID),'MAGENTA'))
    );

    PERFORM Pop_Visited(NodeID) FROM Nodes WHERE ProgramID = _ProgramID AND DeathPhaseID IS NULL;

    PERFORM Set_Visited(_NodeID, TRUE);

    UPDATE Programs SET NodeID = _CallNodeID WHERE ProgramID = _ProgramID AND NodeID = _NodeID RETURNING TRUE INTO STRICT _OK;
ELSE
    _ProgramNodeID := Find_Node(_NodeID := _NodeID, _Descend := FALSE, _Strict := TRUE, _Path := '-> PROGRAM');
    _AllocaNodeID := Find_Node(_NodeID := _ProgramNodeID, _Descend := FALSE, _Strict := TRUE, _Path := '<- ALLOCA');
END IF;

FOR _VariableNodeID IN
SELECT ParentNodeID FROM Edges WHERE ChildNodeID = _AllocaNodeID ORDER BY EdgeID
LOOP
    PERFORM Pop_Node(_VariableNodeID);
END LOOP;

RETURN;
END;
$$;
