CREATE OR REPLACE FUNCTION Kill_Clone(_ClonedRootNodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_KilledEdges bigint;
BEGIN

WITH
NodesToKill AS (
    SELECT NodeID FROM Nodes WHERE ClonedRootNodeID = _ClonedRootNodeID AND DeathPhaseID IS NULL
),
EdgesKilled AS (
    SELECT Kill_Edge(EdgeID) FROM Edges
    WHERE DeathPhaseID IS NULL
    AND   (ParentNodeID IN (SELECT NodeID FROM NodesToKill)
    OR     ChildNodeID  IN (SELECT NodeID FROM NodesToKill))
)
SELECT COUNT(*) INTO _KilledEdges FROM EdgesKilled;

PERFORM Kill_Node(NodeID) FROM Nodes WHERE ClonedRootNodeID = _ClonedRootNodeID AND DeathPhaseID IS NULL;
PERFORM Kill_Node(_ClonedRootNodeID);

PERFORM Log(
    _NodeID   := _ClonedRootNodeID,
    _Severity := 'DEBUG3',
    _Message  := format('Killed clone %s', Colorize(Node(_ClonedRootNodeID),'CYAN'))
);

RETURN TRUE;
END;
$$;
