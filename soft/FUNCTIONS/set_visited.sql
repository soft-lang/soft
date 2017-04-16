CREATE OR REPLACE FUNCTION Set_Visited(_NodeID integer, _Visited boolean)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_OK boolean;
BEGIN
IF _Visited IS NULL THEN
    RAISE EXCEPTION 'Visited must not be set to NULL, NodeID %', _NodeID;
END IF;
UPDATE Nodes
SET Visited = _Visited || Visited[2:array_length(Visited,1)]
WHERE NodeID = _NodeID
AND DeathPhaseID IS NULL
RETURNING TRUE INTO STRICT _OK;
RETURN TRUE;
END;
$$;
