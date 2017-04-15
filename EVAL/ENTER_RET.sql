CREATE OR REPLACE FUNCTION "EVAL"."ENTER_RET"(_NodeID integer) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID                 integer;
_Visited                   integer;
_CallEdgeID                integer;
_CallNodeID                integer;
_FunctionDeclarationNodeID integer;
_ProgramNodeID             integer;
_AllocaNodeID              integer;
_VariableNodeID            integer;
_ChildNodeID               integer;
_OK                        boolean;
BEGIN

SELECT ProgramID, Visited INTO STRICT _ProgramID, _Visited FROM Nodes WHERE NodeID = _NodeID;

_FunctionDeclarationNodeID := Find_Node(_NodeID := _NodeID, _Descend := FALSE, _Strict := FALSE, _Path := '-> FUNCTION_DECLARATION');
IF _FunctionDeclarationNodeID IS NOT NULL THEN
    _AllocaNodeID := Find_Node(_NodeID := _FunctionDeclarationNodeID, _Descend := FALSE, _Strict := TRUE, _Path := '<- ALLOCA');
    SELECT
        CALL.EdgeID,
        CALL.NodeID
    INTO STRICT
        _CallEdgeID,
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

    SELECT Edges.ChildNodeID
    INTO STRICT _ChildNodeID
    FROM Edges
    INNER JOIN Nodes ON Nodes.NodeID = Edges.ChildNodeID
    WHERE Edges.ParentNodeID = _CallNodeID
    AND Edges.DeathPhaseID IS NULL
    AND Nodes.DeathPhaseID IS NULL
    ORDER BY Edges.EdgeID
    LIMIT 1;

    PERFORM Copy_Node(_FromNodeID := _FunctionDeclarationNodeID, _ToNodeID := _CallNodeID);

    PERFORM Log(
        _NodeID   := _NodeID,
        _Severity := 'DEBUG3',
        _Message  := format('Returning function call at %s to %s', Colorize(Node(_NodeID),'CYAN'), Colorize(Node(_CallNodeID),'MAGENTA'))
    );
    PERFORM Kill_Edge(_CallEdgeID);

    UPDATE Nodes SET Visited = _Visited + 1 WHERE NodeID = _CallNodeID  RETURNING TRUE INTO STRICT _OK;

    UPDATE Nodes SET Visited = _Visited + 1 WHERE NodeID IN (
        SELECT Edges.ParentNodeID
        FROM Edges
        INNER JOIN Nodes ON Nodes.NodeID = Edges.ParentNodeID
        WHERE Edges.ChildNodeID = _ChildNodeID
        AND Edges.DeathPhaseID IS NULL
        AND Nodes.DeathPhaseID IS NULL
    );

    UPDATE Nodes SET Visited = _Visited + 1 WHERE NodeID = _ChildNodeID RETURNING TRUE INTO STRICT _OK;

    UPDATE Programs SET NodeID = _ChildNodeID WHERE ProgramID = _ProgramID AND NodeID = _NodeID RETURNING TRUE INTO STRICT _OK;
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
