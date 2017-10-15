CREATE OR REPLACE FUNCTION "EVAL"."LEAVE_PRINT_STATEMENT"(_NodeID integer)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_PrintValueNodeID integer;
BEGIN

SELECT
    Edges.ParentNodeID
INTO STRICT
    _PrintValueNodeID
FROM Edges
INNER JOIN Nodes ON Nodes.NodeID = Edges.ChildNodeID
WHERE Nodes.NodeID = _NodeID
AND Edges.DeathPhaseID IS NULL
AND Nodes.DeathPhaseID IS NULL;

PERFORM Print_Node(_PrintValueNodeID);

PERFORM Set_Reference_Node(
    _ReferenceNodeID := _PrintValueNodeID,
    _NodeID          := _NodeID
);

RETURN;
END;
$$;
