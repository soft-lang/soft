CREATE OR REPLACE FUNCTION "EVAL"."LEAVE_BLOCK_STATEMENT"(_NodeID integer) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_StatementReturnValues boolean;
_LastNodeID            integer;
_OK                    boolean;
BEGIN

SELECT Languages.StatementReturnValues
INTO STRICT     _StatementReturnValues
FROM Nodes
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
INNER JOIN Languages ON Languages.LanguageID = NodeTypes.LanguageID
WHERE NodeID = _NodeID;

IF _StatementReturnValues THEN
    SELECT     ParentNodeID
    INTO STRICT _LastNodeID
    FROM Edges
    WHERE ChildNodeID = _NodeID
    AND DeathPhaseID IS NULL
    ORDER BY EdgeID DESC
    LIMIT 1;
	PERFORM Set_Reference_Node(_ReferenceNodeID := _LastNodeID, _NodeID := _NodeID);
END IF;

RETURN;
END;
$$;
