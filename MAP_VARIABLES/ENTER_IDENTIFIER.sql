CREATE OR REPLACE FUNCTION "MAP_VARIABLES"."ENTER_IDENTIFIER"(_NodeID integer) RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID      integer;
_Name           text;
_VariableNodeID integer;
_ChildNodeID    integer;
_OK             boolean;
BEGIN

IF (SELECT NodeTypes.NodeType = 'VARIABLE'
    FROM Edges
    INNER JOIN Nodes     ON Nodes.NodeID         = Edges.ChildNodeID
    INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
    WHERE Edges.ParentNodeID = _NodeID
    AND   Edges.DeathPhaseID IS NULL
    AND   Nodes.DeathPhaseID IS NULL)
THEN
    -- This is the identifier where the variable is declared by LEAVE_LET_STATEMENT
    RETURN FALSE;
END IF;

SELECT
    Nodes.ProgramID,
    Nodes.TerminalValue
INTO STRICT
    _ProgramID,
    _Name
FROM Nodes
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
INNER JOIN Programs  ON Programs.ProgramID   = Nodes.ProgramID
INNER JOIN Phases    ON Phases.PhaseID       = Programs.PhaseID
INNER JOIN Languages ON Languages.LanguageID = Phases.LanguageID
WHERE Nodes.NodeID = _NodeID
AND Phases.Phase       = 'MAP_VARIABLES'
AND NodeTypes.NodeType = 'IDENTIFIER'
AND Nodes.TerminalType = 'name'::regtype
AND Nodes.DeathPhaseID IS NULL;

_VariableNodeID := Find_Node(
    _NodeID  := _NodeID,
    _Descend := TRUE,
    _Strict  := FALSE,
    _Paths   := ARRAY['<- LET_STATEMENT <- VARIABLE', _Name]
);

IF _VariableNodeID IS NULL THEN
    PERFORM Log(
        _NodeID   := _NodeID,
        _Severity := 'ERROR',
        _Message  := format('Undefined variable %s', Colorize(_Name, 'RED'))
    );
    RETURN FALSE;
END IF;

SELECT Set_Edge_Parent(EdgeID, _ParentNodeID := _VariableNodeID), ChildNodeID INTO STRICT _OK, _ChildNodeID FROM Edges WHERE DeathPhaseID IS NULL AND ParentNodeID = _NodeID;

UPDATE Programs SET NodeID = _ChildNodeID WHERE ProgramID = _ProgramID AND NodeID = _NodeID RETURNING TRUE INTO STRICT _OK;

PERFORM Kill_Node(_NodeID);

RETURN TRUE;
END;
$$;
