CREATE OR REPLACE FUNCTION "MAP_VARIABLES"."LEAVE_LET_STATEMENT"(_NodeID integer) RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_VariableNodeID integer;
_OK             boolean;
BEGIN

SELECT
    SetVariableNode.NodeID
INTO STRICT
    _VariableNodeID
FROM Nodes AS LetStatementNode
INNER JOIN NodeTypes AS LetStatementType ON LetStatementType.NodeTypeID = LetStatementNode.NodeTypeID
INNER JOIN Programs                      ON Programs.ProgramID          = LetStatementNode.ProgramID
INNER JOIN Phases                        ON Phases.PhaseID              = Programs.PhaseID
INNER JOIN Edges                         ON Edges.ChildNodeID           = LetStatementNode.NodeID
INNER JOIN Nodes     AS SetVariableNode  ON SetVariableNode.NodeID      = Edges.ParentNodeID
INNER JOIN NodeTypes AS SetVariableType  ON SetVariableType.NodeTypeID  = SetVariableNode.NodeTypeID
WHERE LetStatementNode.NodeID     = _NodeID
AND Phases.Phase                  = 'MAP_VARIABLES'
AND LetStatementType.NodeType     = 'LET_STATEMENT'
AND SetVariableType.NodeType      = 'SET_VARIABLE'
AND SetVariableNode.TerminalType  = 'name'::regtype
AND LetStatementNode.DeathPhaseID IS NULL
AND SetVariableNode.DeathPhaseID  IS NULL
AND Edges.DeathPhaseID            IS NULL;

SELECT Set_Node_Type(_NodeID := _VariableNodeID, _NodeTypeID := NodeTypeID) INTO STRICT _OK FROM NodeTypes WHERE NodeType = 'VARIABLE';

PERFORM Log(
    _NodeID   := _NodeID,
    _Severity := 'DEBUG2',
    _Message  := format('Variable %s is now declared and can be accessed', Colorize(Node(_VariableNodeID), 'CYAN'))
);

RETURN TRUE;
END;
$$;
