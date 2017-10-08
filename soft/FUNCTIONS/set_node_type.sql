CREATE OR REPLACE FUNCTION Set_Node_Type(_NodeID integer, _NodeTypeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_OK boolean;
BEGIN
UPDATE Nodes
SET NodeTypeID = _NodeTypeID
WHERE NodeID = _NodeID
AND DeathPhaseID IS NULL
RETURNING TRUE INTO STRICT _OK;
RETURN TRUE;
END;
$$;
