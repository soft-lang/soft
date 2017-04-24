CREATE OR REPLACE FUNCTION Get_Visited(_NodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_OK boolean;
_Visited boolean;
BEGIN
SELECT Visited
INTO STRICT _Visited
FROM Nodes
WHERE NodeID = _NodeID
AND DeathPhaseID IS NULL;
IF _Visited IS NULL THEN
    RAISE EXCEPTION 'Visited cannot be NULL, NodeID %', _NodeID;
END IF;
RETURN _Visited;
END;
$$;
