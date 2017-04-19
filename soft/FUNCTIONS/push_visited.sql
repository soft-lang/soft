CREATE OR REPLACE FUNCTION Push_Visited(_NodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_OK boolean;
BEGIN
UPDATE Nodes
SET Visited = CASE WHEN Visited[array_length(Visited,1)] IS NOT NULL THEN FALSE ELSE NULL::boolean END || Visited
WHERE NodeID = _NodeID
AND DeathPhaseID IS NULL
RETURNING TRUE INTO STRICT _OK;
RETURN TRUE;
END;
$$;
