CREATE OR REPLACE FUNCTION Discard_Node(_NodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_ChildNodeID integer;
_OK          boolean;
BEGIN

SELECT Kill_Edge(EdgeID), ChildNodeID INTO STRICT _OK, _ChildNodeID FROM Edges WHERE DeathPhaseID IS NULL AND ParentNodeID = _NodeID;
PERFORM Kill_Node(_NodeID);

RETURN TRUE;
END;
$$;
