CREATE OR REPLACE FUNCTION Set_Edge_Parent(_EdgeID integer, _ParentNodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_OK boolean;
BEGIN
UPDATE Edges
SET ParentNodeID = _ParentNodeID
WHERE     EdgeID = _EdgeID
AND DeathPhaseID IS NULL
RETURNING TRUE INTO STRICT _OK;
RETURN TRUE;
END;
$$;
