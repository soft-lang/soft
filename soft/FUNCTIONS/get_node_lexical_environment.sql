CREATE OR REPLACE FUNCTION Get_Node_Lexical_Environment(_NodeID integer)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_ClonedRootNodeID integer;
_Env              integer;
BEGIN

SELECT
    ClonedRootNodeID
INTO STRICT
    _ClonedRootNodeID
FROM Nodes
WHERE NodeID = _NodeID;

IF EXISTS (SELECT 1 FROM Nodes WHERE ClonedRootNodeID = _NodeID) THEN
    _ClonedRootNodeID := _NodeID;
END IF;

IF _ClonedRootNodeID IS NULL THEN
    RETURN 0;
END IF;

SELECT ROW_NUMBER INTO STRICT _Env
FROM (
    SELECT ClonedRootNodeID, ROW_NUMBER() OVER () FROM (
        SELECT DISTINCT ClonedRootNodeID FROM Nodes WHERE ClonedRootNodeID IS NOT NULL ORDER BY ClonedRootNodeID
    ) AS X
) AS Y
WHERE ClonedRootNodeID = _ClonedRootNodeID;

RETURN _Env;
END;
$$;
