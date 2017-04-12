CREATE OR REPLACE FUNCTION Kill_Edge(_EdgeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_OK boolean;
BEGIN
UPDATE Edges
SET DeathPhaseID = Programs.PhaseID
FROM Programs
WHERE Programs.ProgramID = Edges.ProgramID
AND Edges.EdgeID = _EdgeID
AND Edges.DeathPhaseID IS NULL
RETURNING TRUE INTO STRICT _OK;
RAISE NOTICE 'Killed EdgeID %', _EdgeID;
RETURN TRUE;
END;
$$;
