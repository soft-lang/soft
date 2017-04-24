CREATE OR REPLACE FUNCTION Kill_Clone(_ClonedRootNodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
BEGIN

PERFORM Kill_Edge(EdgeID) FROM Edges WHERE ClonedRootNodeID = _ClonedRootNodeID AND DeathPhaseID IS NULL;
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
