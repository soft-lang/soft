CREATE OR REPLACE FUNCTION "EVAL"."ENTER_CALL"(_NodeID integer) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_RetNodeID integer;
_Walkable  boolean;
BEGIN

SELECT
    RET.NodeID,
    Nodes.Walkable
INTO
    _RetNodeID,
    _Walkable
FROM (
    SELECT
        EdgeID,
        ChildNodeID AS NodeID
    FROM Edges
    WHERE ParentNodeID  = _NodeID
    AND   DeathPhaseID IS NULL
    ORDER BY EdgeID DESC
    LIMIT 1
) AS RET
INNER JOIN Nodes     ON Nodes.NodeID         = RET.NodeID
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
WHERE Nodes.DeathPhaseID IS NULL
AND   NodeTypes.NodeType = 'RET';
IF FOUND AND NOT _Walkable THEN
    PERFORM Log(
        _NodeID   := _NodeID,
        _Severity := 'DEBUG3',
        _Message  := format('Function call again at %s, making %s walkable again', Colorize(Node(_NodeID),'CYAN'), Colorize(Node(_RetNodeID),'MAGENTA'))
    );
--    PERFORM Set_Walkable(_RetNodeID, TRUE);
END IF;

RETURN;
END;
$$;
