CREATE OR REPLACE FUNCTION Call_Args(_CallNodeID integer)
RETURNS integer[]
LANGUAGE plpgsql
AS $$
DECLARE
_ArgumentNodeIDs integer[];
BEGIN
SELECT array_agg(ParentNodeID ORDER BY EdgeID)
INTO STRICT _ArgumentNodeIDs
FROM (
    SELECT EdgeID, ParentNodeID FROM Edges
    WHERE ChildNodeID = _CallNodeID
    AND DeathPhaseID IS NULL
    ORDER BY EdgeID
    OFFSET 1
) AS X;
RETURN _ArgumentNodeIDs;
END;
$$;
