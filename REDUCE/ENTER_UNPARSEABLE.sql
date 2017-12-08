CREATE OR REPLACE FUNCTION "REDUCE"."ENTER_UNPARSEABLE"(_NodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID     integer;
_EdgeIDs       integer[];
_ParentNodeIDs integer[];
_OK            boolean;
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
    _SaveDOTIR  := FALSE
);

WITH RECURSIVE
Parents AS (
    SELECT
        Edges.EdgeID,
        Edges.ParentNodeID
    FROM Nodes
    INNER JOIN Edges ON Edges.ChildNodeID = Nodes.NodeID
    WHERE Nodes.NodeID = _NodeID
    AND   Nodes.DeathPhaseID IS NULL
    AND   Edges.DeathPhaseID IS NULL
    UNION ALL
    SELECT
        Edges.EdgeID,
        Edges.ParentNodeID
    FROM Parents
    INNER JOIN Edges ON Edges.ChildNodeID = Parents.ParentNodeID
    INNER JOIN Nodes ON Nodes.NodeID      = Edges.ParentNodeID
    WHERE Nodes.DeathPhaseID IS NULL
    AND   Edges.DeathPhaseID IS NULL
)
SELECT
    array_agg(EdgeID),
    array_agg(ParentNodeID)
INTO
    _EdgeIDs,
    _ParentNodeIDs
FROM Parents;

PERFORM Set_Program_Node(_NodeID := Child(_NodeID));

PERFORM Kill_Edge(unnest) FROM unnest(_EdgeIDs);
PERFORM Kill_Node(unnest) FROM unnest(_ParentNodeIDs);

PERFORM Kill_Edge(EdgeID) FROM Edges WHERE DeathPhaseID IS NULL AND ParentNodeID = _NodeID;
PERFORM Kill_Node(_NodeID);

RETURN TRUE;
END;
$$;
