CREATE OR REPLACE FUNCTION Set_Walkable(_NodeID integer, _Walkable boolean)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_OK boolean;
BEGIN
UPDATE Nodes
SET Walkable = _Walkable
WHERE NodeID = _NodeID
AND DeathPhaseID IS NULL
RETURNING TRUE INTO STRICT _OK;
RETURN TRUE;
END;
$$;
