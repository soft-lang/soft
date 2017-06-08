CREATE OR REPLACE FUNCTION Set_Reference_Node(_ReferenceNodeID integer, _NodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_OK boolean;
BEGIN
UPDATE Nodes SET ReferenceNodeID = Dereference(_ReferenceNodeID) WHERE NodeID = _NodeID RETURNING TRUE INTO STRICT _OK;
RETURN TRUE;
END;
$$;
