CREATE OR REPLACE FUNCTION "DISCARD"."ENTER_COMMENT"(_NodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID   integer;
_ChildNodeID integer;
_OK          boolean;
BEGIN

SELECT
    Nodes.ProgramID
INTO STRICT
    _ProgramID
FROM Nodes
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
INNER JOIN Programs  ON Programs.ProgramID   = Nodes.ProgramID
INNER JOIN Phases    ON Phases.PhaseID       = Programs.PhaseID
INNER JOIN Languages ON Languages.LanguageID = Phases.LanguageID
WHERE Nodes.NodeID     = _NodeID
AND Phases.Phase       = 'DISCARD'
AND NodeTypes.NodeType = 'COMMENT';

PERFORM Log(
    _NodeID   := _NodeID,
    _Severity := 'DEBUG3',
    _Message  := format('Killing comment NodeID %s', _NodeID),
    _SaveDOTIR  := FALSE
);

SELECT Kill_Edge(EdgeID), ChildNodeID INTO STRICT _OK, _ChildNodeID FROM Edges WHERE DeathPhaseID IS NULL AND ParentNodeID = _NodeID;
PERFORM Kill_Node(_NodeID);
PERFORM Set_Program_Node(_NodeID := _ChildNodeID);

RETURN TRUE;
END;
$$;
