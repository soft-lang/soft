CREATE OR REPLACE FUNCTION "EVAL"."LEAVE_CALL"(_NodeID integer) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID                 integer;
_RetVisited                integer;
_RetNodeID                 integer;
_RetEdgeID                 integer;
_NextNodeID                integer;
_FunctionDeclarationNodeID integer;
_FunctionInstanceNodeID    integer;
_AllocaNodeID              integer;
_VariableNodeID            integer;
_OK                        boolean;
BEGIN

SELECT ProgramID INTO STRICT _ProgramID FROM Nodes WHERE NodeID = _NodeID;

SELECT
    RET.NodeID,
    RET.EdgeID
INTO
    _RetNodeID,
    _RetEdgeID
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
AND   NodeTypes.NodeType = 'RET'
AND   Nodes.Visited      IS TRUE;
IF FOUND THEN
    PERFORM Log(
        _NodeID   := _NodeID,
        _Severity := 'DEBUG3',
        _Message  := format('Returning function call at %s from %s', Colorize(Node(_NodeID),'CYAN'), Colorize(Node(_RetNodeID),'MAGENTA'))
    );
    PERFORM Kill_Edge(_RetEdgeID);

    PERFORM Copy_Node(_FromNodeID := _RetNodeID, _ToNodeID := _NodeID);

    _FunctionInstanceNodeID := Find_Node(_NodeID := _RetNodeID, _Descend := FALSE, _Strict := TRUE, _Path := '-> FUNCTION_DECLARATION');

    PERFORM Kill_Clone(_FunctionInstanceNodeID);

    -- SELECT Edges.ChildNodeID
    -- INTO _NextNodeID
    -- FROM Edges
    -- INNER JOIN Nodes ON Nodes.NodeID = Edges.ChildNodeID
    -- WHERE Edges.ParentNodeID = _NodeID
    -- AND Nodes.DeathPhaseID IS NULL
    -- AND Edges.DeathPhaseID IS NULL
    -- ORDER BY Edges.EdgeID
    -- LIMIT 1;
    -- UPDATE Programs SET NodeID = _NextNodeID WHERE ProgramID = _ProgramID AND NodeID = _NodeID RETURNING TRUE INTO STRICT _OK;
    -- PERFORM Set_Visited(_NodeID := _NextNodeID, _Visited := TRUE);
ELSE
    _FunctionDeclarationNodeID := Find_Node(_NodeID := _NodeID, _Descend := FALSE, _Strict := TRUE, _Path := '<- FUNCTION_LABEL <- FUNCTION_DECLARATION');
    _FunctionInstanceNodeID    := Clone_Node(_NodeID := _FunctionDeclarationNodeID);
    _RetNodeID                 := Find_Node(_NodeID := _FunctionInstanceNodeID, _Descend := FALSE, _Strict := TRUE, _Path := '<- RET');
    PERFORM Log(
        _NodeID   := _NodeID,
        _Severity := 'DEBUG3',
        _Message  := format('Outgoing function call at %s to %s', Colorize(Node(_NodeID),'CYAN'), Colorize(Node(_FunctionInstanceNodeID),'MAGENTA'))
    );

    PERFORM Set_Visited(_NodeID := _FunctionInstanceNodeID, _Visited := TRUE);
    UPDATE Programs SET NodeID = _FunctionInstanceNodeID WHERE ProgramID = _ProgramID AND NodeID = _NodeID RETURNING TRUE INTO STRICT _OK;
    PERFORM New_Edge(
        _ProgramID    := _ProgramID,
        _ParentNodeID := _NodeID,
        _ChildNodeID  := _RetNodeID
    );
END IF;

RETURN;
END;
$$;
