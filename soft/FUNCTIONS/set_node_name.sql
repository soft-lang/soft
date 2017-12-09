CREATE OR REPLACE FUNCTION Set_Node_Name(_NodeID integer, _NodeName name)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_OK boolean;
BEGIN
UPDATE Nodes
SET NodeName = _NodeName
WHERE NodeID = _NodeID
AND DeathPhaseID IS NULL
AND NodeName IS NULL
RETURNING TRUE INTO STRICT _OK;
RETURN TRUE;
END;
$$;
