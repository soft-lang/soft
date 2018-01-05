CREATE OR REPLACE FUNCTION Call_Args(_CallNodeID integer)
RETURNS integer[]
LANGUAGE plpgsql
AS $$
DECLARE
_ArgumentNodeIDs integer[];
BEGIN
SELECT array_agg(ParentNodeID ORDER BY EdgeID)
INTO STRICT _ArgumentNodeIDs
FROM Edges
WHERE ChildNodeID = Parent(_CallNodeID,'ARGUMENTS')
AND DeathPhaseID IS NULL;

RETURN _ArgumentNodeIDs;
END;
$$;
