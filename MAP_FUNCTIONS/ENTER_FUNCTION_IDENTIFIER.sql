CREATE OR REPLACE FUNCTION "MAP_FUNCTIONS"."ENTER_FUNCTION_IDENTIFIER"(_NodeID integer) RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID                 integer;
_AllocaNodeID              integer;
_AllocaEdgeID              integer;
_Name                      text;
_FunctionDeclarationNodeID integer;
_FunctionLabelNodeID       integer;
_CallNodeID                integer;
_OK                        boolean;
BEGIN

_AllocaNodeID := Find_Node(_NodeID := _NodeID, _Descend := TRUE, _Strict := TRUE, _Path := '<- ALLOCA');

SELECT
    Nodes.ProgramID,
    Nodes.TerminalValue,
    Edges.ChildNodeID
INTO STRICT
    _ProgramID,
    _Name,
    _CallNodeID
FROM Nodes
INNER JOIN Edges              ON Edges.ParentNodeID = Nodes.NodeID
INNER JOIN Nodes AS ChildNode ON ChildNode.NodeID   = Edges.ChildNodeID
WHERE Nodes.NodeID            = _NodeID
AND   Nodes.DeathPhaseID      IS NULL
AND   Edges.DeathPhaseID      IS NULL
AND   ChildNode.DeathPhaseID  IS NULL;

_FunctionDeclarationNodeID := Find_Node(
    _NodeID  := _NodeID,
    _Descend := TRUE,
    _Strict  := FALSE,
    _Paths   := ARRAY['<- FUNCTION_LABEL', _Name, '<- FUNCTION_DECLARATION']
);
IF _FunctionDeclarationNodeID IS NOT NULL THEN
    SELECT ChildNodeID INTO STRICT _FunctionLabelNodeID FROM Edges WHERE DeathPhaseID IS NULL AND ParentNodeID = _FunctionDeclarationNodeID;
ELSE
    -- Handle self-calling recursive calls
    _FunctionLabelNodeID := Find_Node(
        _NodeID  := _NodeID,
        _Descend := TRUE,
        _Strict  := FALSE,
        _Paths   := ARRAY['-> FUNCTION_DECLARATION -> FUNCTION_LABEL', _Name]
    );
    IF _FunctionLabelNodeID IS NULL THEN
        PERFORM Log(
            _NodeID   := _NodeID,
            _Severity := 'ERROR',
            _Message  := format('Undeclared function %s', Colorize(_Name, 'RED'))
        );
        RETURN FALSE;
    END IF;
END IF;

UPDATE Programs SET NodeID = _CallNodeID WHERE ProgramID = _ProgramID AND NodeID = _NodeID RETURNING TRUE INTO STRICT _OK;

SELECT Set_Edge_Parent(_EdgeID := EdgeID, _ParentNodeID := _FunctionLabelNodeID) INTO STRICT _OK FROM Edges WHERE DeathPhaseID IS NULL AND ParentNodeID = _NodeID;

PERFORM Kill_Node(_NodeID);

_AllocaEdgeID := New_Edge(
    _ProgramID    := _ProgramID,
    _ParentNodeID := _CallNodeID,
    _ChildNodeID  := _AllocaNodeID
);

RETURN TRUE;
END;
$$;
