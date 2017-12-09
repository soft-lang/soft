CREATE OR REPLACE FUNCTION Set_Edge_Child(_EdgeID integer, _ChildNodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_OK boolean;
BEGIN
UPDATE Edges
SET ChildNodeID  = _ChildNodeID
WHERE     EdgeID = _EdgeID
AND DeathPhaseID IS NULL
RETURNING TRUE INTO STRICT _OK;
RETURN TRUE;
END;
$$;
