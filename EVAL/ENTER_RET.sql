CREATE OR REPLACE FUNCTION "EVAL"."ENTER_RET"(_NodeID integer, _ReturnValueNodeID integer DEFAULT NULL)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_CallNodeID                integer;
_FunctionDeclarationNodeID integer;
_ProgramNodeID             integer;
_OK                        boolean;
BEGIN

IF (Language(_NodeID)).ImplicitReturnValues AND _ReturnValueNodeID IS NULL THEN
    SELECT         E2.ParentNodeID
    INTO STRICT _ReturnValueNodeID
    FROM Edges       AS E1
    INNER JOIN Edges AS E2 ON E2.ChildNodeID = E1.ChildNodeID
    INNER JOIN Nodes       ON Nodes.NodeID   = E2.ParentNodeID
    WHERE  E1.ParentNodeID   = _NodeID
    AND    E2.EdgeID         < E1.EdgeID
    AND    E1.DeathPhaseID   IS NULL
    AND    E2.DeathPhaseID   IS NULL
    AND Nodes.DeathPhaseID   IS NULL
    ORDER BY E2.EdgeID DESC
    LIMIT 1;
END IF;

_FunctionDeclarationNodeID := Find_Node(
    _NodeID  := _NodeID,
    _Descend := FALSE,
    _Strict  := FALSE,
    _Path    := '-> FUNCTION_DECLARATION'
);
IF _FunctionDeclarationNodeID IS NOT NULL THEN
    IF Node_Name(_FunctionDeclarationNodeID) = 'init'
    AND Node_Type(Child(_FunctionDeclarationNodeID)) = 'CLASS_DECLARATION'
    THEN
        _ReturnValueNodeID := Child(_FunctionDeclarationNodeID);
    END IF;

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
    PERFORM Log(
        _NodeID   := _NodeID,
        _Severity := 'DEBUG3',
        _Message  := format('Returning function call at %s to %s', Colorize(Node(_NodeID),'CYAN'), Colorize(Node(_CallNodeID),'MAGENTA'))
    );
    PERFORM Set_Program_Node(_CallNodeID, 'LEAVE');
    IF _ReturnValueNodeID IS NOT NULL THEN
        PERFORM Log(
            _NodeID   := _NodeID,
            _Severity := 'DEBUG3',
            _Message  := format('Setting reference node since node type for %s is %s', Colorize(Node(_CallNodeID),'CYAN'), Colorize(Node_Type(Dereference(_CallNodeID)),'MAGENTA'))
        );
        PERFORM Set_Reference_Node(_ReferenceNodeID := _ReturnValueNodeID, _NodeID := _CallNodeID);
    END IF;
ELSE
    _ProgramNodeID := Find_Node(_NodeID := _NodeID, _Descend := FALSE, _Strict := TRUE, _Path := '-> PROGRAM');
    IF _ReturnValueNodeID IS NOT NULL THEN
        PERFORM Set_Reference_Node(_ReferenceNodeID := _ReturnValueNodeID, _NodeID := _ProgramNodeID);
    END IF;
END IF;

RETURN;
END;
$$;
