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

_FunctionDeclarationNodeID := Find_Node(_NodeID := _NodeID, _Descend := FALSE, _Strict := TRUE, _Path := '<- FUNCTION_DECLARATION');

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
        Edges.EdgeID,
        Edges.ChildNodeID AS NodeID
    FROM Edges
    WHERE Edges.ParentNodeID  = _NodeID
    AND   Edges.DeathPhaseID IS NULL
    ORDER BY Edges.EdgeID DESC
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
    PERFORM Copy_Node(_FromNodeID := _RetNodeID, _ToNodeID := _NodeID);
    PERFORM Set_Walkable(_RetNodeID, FALSE);
ELSE
    _FunctionInstanceNodeID := Find_Node(_NodeID := _RetNodeID, _Descend := FALSE, _Strict := TRUE, _Path := '-> FUNCTION_DECLARATION');
    PERFORM Log(
        _NodeID   := _NodeID,
        _Severity := 'DEBUG3',
        _Message  := format('Outgoing function call at %s to %s', Colorize(Node(_NodeID),'CYAN'), Colorize(Node(_FunctionInstanceNodeID),'MAGENTA'))
    );
    PERFORM Set_Walkable(_RetNodeID, TRUE);
    UPDATE Programs SET NodeID = _FunctionInstanceNodeID WHERE ProgramID = _ProgramID AND NodeID = _NodeID RETURNING TRUE INTO STRICT _OK;
END IF;

RETURN;
END;
$$;
