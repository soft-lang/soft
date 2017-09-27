CREATE OR REPLACE FUNCTION Get_Env(_NodeID integer)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_ClonedFromNodeID integer;
_ClonedRootNodeID integer;
BEGIN

SELECT
    ClonedFromNodeID,
    ClonedRootNodeID
INTO STRICT
    _ClonedFromNodeID,
    _ClonedRootNodeID
FROM Nodes
WHERE NodeID = _NodeID;

IF EXISTS (SELECT 1 FROM Nodes WHERE ClonedRootNodeID = _NodeID) THEN
    RETURN _NodeID;
ELSIF _ClonedRootNodeID IS NOT NULL THEN
    RETURN _ClonedRootNodeID;
END IF;

RETURN 0;
END;
$$;
