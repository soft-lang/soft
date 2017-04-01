CREATE OR REPLACE FUNCTION Kill_Node(_NodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_OK boolean;
BEGIN
UPDATE Nodes
SET DeathPhaseID = Programs.PhaseID
FROM Programs
WHERE Programs.ProgramID = Nodes.ProgramID
AND Nodes.NodeID = _NodeID
AND Nodes.DeathPhaseID IS NULL
RETURNING TRUE INTO STRICT _OK;
RETURN TRUE;
END;
$$;
