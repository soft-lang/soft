CREATE OR REPLACE FUNCTION "MAP_FUNCTIONS"."ENTER_IDENTIFIER"(_NodeID integer) RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID                 integer;
_AllocaNodeID              integer;
_Name                      text;
_FunctionNameNodeID        integer;
_FunctionDeclarationNodeID integer;
_FunctionLabelNodeID       integer;
_CallNodeID                integer;
_OK                        boolean;
BEGIN

_FunctionNameNodeID := Find_Node(
    _NodeID  := _NodeID,
    _Descend := FALSE,
    _Strict  := FALSE,
    _Path    := '-> FUNCTION_NAME'
);

_AllocaNodeID := Find_Node(_NodeID := _NodeID, _Descend := TRUE, _Strict := TRUE, _Path := '<- ALLOCA');

IF _FunctionNameNodeID IS NULL THEN
    RETURN FALSE;
END IF;

SELECT
    Edges.ChildNodeID
INTO STRICT
    _CallNodeID
FROM Edges
INNER JOIN Nodes AS ChildNode ON ChildNode.NodeID = Edges.ChildNodeID
WHERE Edges.ParentNodeID      = _FunctionNameNodeID
AND   Edges.DeathPhaseID      IS NULL
AND   ChildNode.DeathPhaseID  IS NULL;

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
AND Phases.Phase       = 'MAP_FUNCTIONS'
AND NodeTypes.NodeType = 'IDENTIFIER'
AND Nodes.TerminalType = 'name'::regtype
AND Nodes.DeathPhaseID IS NULL;

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
END IF;

SELECT Kill_Edge(EdgeID) INTO STRICT _OK FROM Edges WHERE DeathPhaseID IS NULL AND ChildNodeID = _FunctionNameNodeID AND ParentNodeID = _NodeID;

UPDATE Programs SET NodeID = _CallNodeID WHERE ProgramID = _ProgramID AND NodeID = _NodeID RETURNING TRUE INTO STRICT _OK;

PERFORM Kill_Node(_NodeID);
SELECT Set_Edge_Parent(_EdgeID := EdgeID, _ParentNodeID := _FunctionLabelNodeID) INTO STRICT _OK FROM Edges WHERE DeathPhaseID IS NULL AND ParentNodeID = _FunctionNameNodeID;
PERFORM Kill_Node(_FunctionNameNodeID);

PERFORM New_Edge(
    _ProgramID    := _ProgramID,
    _ParentNodeID := _CallNodeID,
    _ChildNodeID  := _AllocaNodeID
);

RETURN TRUE;
END;
$$;
