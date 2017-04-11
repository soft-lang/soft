CREATE OR REPLACE FUNCTION Set_Visited(_NodeID integer, _Visited integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_OK boolean;
BEGIN
UPDATE Nodes
SET Visited = _Visited
WHERE NodeID = _NodeID
AND DeathPhaseID IS NULL
RETURNING TRUE INTO STRICT _OK;
RETURN TRUE;
END;
$$;
