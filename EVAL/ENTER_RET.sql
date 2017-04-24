CREATE OR REPLACE FUNCTION "EVAL"."ENTER_RET"(_NodeID integer, _ExplicitReturnValue boolean DEFAULT FALSE) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID                 integer;
_ImplicitReturnValues      boolean;
_ReturnValueNodeID         integer;
_CallNodeID                integer;
_FunctionDeclarationNodeID integer;
_ProgramNodeID             integer;
_AllocaNodeID              integer;
_VariableNodeID            integer;
_OK                        boolean;
BEGIN

SELECT
    Nodes.ProgramID,
    Languages.ImplicitReturnValues
INTO STRICT
    _ProgramID,
    _ImplicitReturnValues
FROM Nodes
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
INNER JOIN Languages ON Languages.LanguageID = NodeTypes.LanguageID
WHERE NodeID = _NodeID;

IF _ImplicitReturnValues AND NOT _ExplicitReturnValue THEN
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

_FunctionDeclarationNodeID := Find_Node(_NodeID := _NodeID, _Descend := FALSE, _Strict := FALSE, _Path := '-> FUNCTION_DECLARATION');
IF _FunctionDeclarationNodeID IS NOT NULL THEN
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
    PERFORM Set_Visited(_NodeID, TRUE);
    UPDATE Programs SET NodeID = _CallNodeID WHERE ProgramID = _ProgramID AND NodeID = _NodeID RETURNING TRUE INTO STRICT _OK;
    IF _ReturnValueNodeID IS NOT NULL THEN
        PERFORM Copy_Node(_FromNodeID := _ReturnValueNodeID, _ToNodeID := _NodeID);
    END IF;
ELSE
    _ProgramNodeID := Find_Node(_NodeID := _NodeID, _Descend := FALSE, _Strict := TRUE, _Path := '-> PROGRAM');
    IF _ReturnValueNodeID IS NOT NULL THEN
        PERFORM Copy_Node(_FromNodeID := _ReturnValueNodeID, _ToNodeID := _ProgramNodeID);
    END IF;
END IF;

RETURN;
END;
$$;
