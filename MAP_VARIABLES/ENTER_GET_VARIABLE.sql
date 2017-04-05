CREATE OR REPLACE FUNCTION "MAP_VARIABLES"."ENTER_GET_VARIABLE"(_NodeID integer) RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_Name           text;
_VariableNodeID integer;
_OK             boolean;
BEGIN

SELECT
    Nodes.TerminalValue
INTO STRICT
    _Name
FROM Nodes
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
INNER JOIN Programs  ON Programs.ProgramID   = Nodes.ProgramID
INNER JOIN Phases    ON Phases.PhaseID       = Programs.PhaseID
INNER JOIN Languages ON Languages.LanguageID = Phases.LanguageID
WHERE Nodes.NodeID = _NodeID
AND Phases.Phase       = 'MAP_VARIABLES'
AND NodeTypes.NodeType = 'GET_VARIABLE'
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

SELECT Set_Edge_Parent(EdgeID, _ParentNodeID := _VariableNodeID) INTO STRICT _OK FROM Edges WHERE DeathPhaseID IS NULL AND ParentNodeID = _NodeID;

PERFORM Kill_Node(_NodeID);

RETURN TRUE;
END;
$$;
