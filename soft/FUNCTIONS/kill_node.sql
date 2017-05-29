CREATE OR REPLACE FUNCTION Kill_Node(_NodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_OK                boolean;
_NodeAlreadyDead   boolean;
_EdgeIDsStillAlive integer[];
_ProgramID         integer;
BEGIN
SELECT
    Nodes.DeathPhaseID IS NOT NULL,
    array_agg(Edges.EdgeID)
INTO
    _NodeAlreadyDead,
    _EdgeIDsStillAlive
FROM Nodes
LEFT JOIN Edges ON Nodes.NodeID IN (Edges.ParentNodeID, Edges.ChildNodeID)
               AND Edges.DeathPhaseID IS NULL
WHERE Nodes.NodeID = _NodeID
GROUP BY 1;
IF NOT FOUND THEN
    RAISE EXCEPTION 'NodeID % does not exist', _NodeID;
END IF;
IF _NodeAlreadyDead THEN
    RAISE EXCEPTION 'NodeID % is already dead', _NodeID;
END IF;
IF array_length(_EdgeIDsStillAlive,1) = 1 AND _EdgeIDsStillAlive[1] IS NOT NULL THEN
    RAISE EXCEPTION 'EdgeID % is still alive for NodeID %', _EdgeIDsStillAlive, _NodeID;
ELSIF array_length(_EdgeIDsStillAlive,1) > 1 THEN
    RAISE EXCEPTION 'NodeID % has EdgeIDs that are still alive: %', _NodeID, _EdgeIDsStillAlive;
END IF;

SELECT ProgramID INTO _ProgramID FROM Programs WHERE NodeID = _NodeID;
IF FOUND THEN
    RAISE EXCEPTION 'NodeID % is current node for ProgramID %', _NodeID, _ProgramID;
END IF;

UPDATE Nodes
SET DeathPhaseID = Programs.PhaseID, DeathTime = clock_timestamp()
FROM Programs
WHERE Programs.ProgramID = Nodes.ProgramID
AND Nodes.NodeID = _NodeID
AND Nodes.DeathPhaseID IS NULL
AND NOT EXISTS (SELECT 1 FROM Edges WHERE Edges.DeathPhaseID IS NULL AND Nodes.NodeID IN (Edges.ParentNodeID, Edges.ChildNodeID))
RETURNING TRUE INTO STRICT _OK;
RETURN TRUE;
END;
$$;
