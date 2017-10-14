CREATE OR REPLACE FUNCTION "REDUCE"."ENTER_UNPARSEABLE"(_NodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID    integer;
_ChildNodeID  integer;
_ParentNodeID integer;
_OK           boolean;
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
AND Phases.Phase       = 'REDUCE'
AND NodeTypes.NodeType = 'UNPARSEABLE';

PERFORM Log(
    _NodeID   := _NodeID,
    _Severity := 'DEBUG3',
    _Message  := format('Killing unparsable NodeID %s', _NodeID),
    _SaveDOTIR  := TRUE
);

SELECT Kill_Edge(EdgeID), ParentNodeID INTO STRICT _OK, _ParentNodeID FROM Edges WHERE DeathPhaseID IS NULL AND ChildNodeID = _NodeID;
PERFORM Kill_Node(_ParentNodeID);
SELECT Kill_Edge(EdgeID), ChildNodeID INTO STRICT _OK, _ChildNodeID FROM Edges WHERE DeathPhaseID IS NULL AND ParentNodeID = _NodeID;
PERFORM Kill_Node(_NodeID);

PERFORM Set_Program_Node(_NodeID := _ChildNodeID);

RETURN TRUE;
END;
$$;
