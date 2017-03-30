CREATE OR REPLACE FUNCTION soft.Set_Visited(_NodeID integer, _Visited integer)
RETURNS boolean
LANGUAGE plpgsql
SET search_path TO soft, public, pg_temp
AS $$
DECLARE
_OK boolean;
BEGIN
RAISE NOTICE 'Setting Visited to % for NodeID %', _Visited, _NodeID;
UPDATE Nodes SET Visited = _Visited WHERE NodeID = _NodeID RETURNING TRUE INTO STRICT _OK;
RETURN TRUE;
END;
$$;
