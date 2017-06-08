CREATE OR REPLACE FUNCTION "EVAL"."LEAVE_CALL"(_NodeID integer) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID                 integer;
_Walkable                   boolean;
_RetNodeID                 integer;
_RetEdgeID                 integer;
_NextNodeID                integer;
_FunctionDeclarationNodeID integer;
_FunctionInstanceNodeID    integer;
_AllocaNodeID              integer;
_VariableNodeID            integer;
_ReturningCall             boolean;
_OK                        boolean;
BEGIN

SELECT ProgramID INTO STRICT _ProgramID FROM Nodes WHERE NodeID = _NodeID;

SELECT                  X.ParentNodeID
INTO STRICT _FunctionDeclarationNodeID
FROM (
    SELECT ParentNodeID
    FROM Edges
    WHERE ChildNodeID  = _NodeID
    AND   DeathPhaseID IS NULL
    ORDER BY EdgeID
    LIMIT 1
) AS X
INNER JOIN Nodes     ON Nodes.NodeID         = X.ParentNodeID
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
WHERE Nodes.DeathPhaseID IS NULL
AND   NodeTypes.NodeType = 'FUNCTION_DECLARATION';

SELECT
    RET.NodeID,
    RET.EdgeID,
    Nodes.Walkable IS NOT NULL
INTO
    _RetNodeID,
    _RetEdgeID,
    _ReturningCall
FROM (
    SELECT
        EdgeID,
        ChildNodeID AS NodeID
    FROM Edges
    WHERE ParentNodeID  = _NodeID
    AND   DeathPhaseID IS NULL
    ORDER BY EdgeID DESC
    LIMIT 1
) AS RET
INNER JOIN Nodes     ON Nodes.NodeID         = RET.NodeID
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
WHERE Nodes.DeathPhaseID IS NULL
AND   NodeTypes.NodeType = 'RET';
IF NOT FOUND THEN
    _FunctionInstanceNodeID := Clone_Node(_NodeID := _FunctionDeclarationNodeID, _SelfRef := FALSE);
    _RetNodeID := Find_Node(_NodeID := _FunctionInstanceNodeID, _Descend := FALSE, _Strict := TRUE, _Path := '<- RET');
    PERFORM Set_Walkable(_FunctionInstanceNodeID, TRUE);
    PERFORM New_Edge(
        _ProgramID    := _ProgramID,
        _ParentNodeID := _NodeID,
        _ChildNodeID  := _RetNodeID
    );
END IF;

IF _ReturningCall THEN
    PERFORM Log(
        _NodeID   := _NodeID,
        _Severity := 'DEBUG3',
        _Message  := format('Returning function call at %s from %s', Colorize(Node(_NodeID),'CYAN'), Colorize(Node(_RetNodeID),'MAGENTA'))
    );
    PERFORM Set_Walkable(_RetNodeID, FALSE);
ELSE
    _FunctionInstanceNodeID := Find_Node(_NodeID := _RetNodeID, _Descend := FALSE, _Strict := TRUE, _Path := '-> FUNCTION_DECLARATION');
    PERFORM Log(
        _NodeID   := _NodeID,
        _Severity := 'DEBUG3',
        _Message  := format('Outgoing function call at %s to %s', Colorize(Node(_NodeID),'CYAN'), Colorize(Node(_FunctionInstanceNodeID),'MAGENTA'))
    );
    PERFORM Set_Walkable(_RetNodeID, TRUE);
    UPDATE Programs SET NodeID = _FunctionInstanceNodeID, Direction = 'ENTER' WHERE ProgramID = _ProgramID AND NodeID = _NodeID RETURNING TRUE INTO STRICT _OK;
END IF;

RETURN;
END;
$$;
