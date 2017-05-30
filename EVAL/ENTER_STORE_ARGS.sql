CREATE OR REPLACE FUNCTION "EVAL"."ENTER_STORE_ARGS"(_NodeID integer) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_RetNodeID       integer;
_CallNodeID      integer;
_CopyFromNodeIDs integer[];
_CopyToNodeIDs   integer[];
_ClonedNodeID    integer;
_OK              boolean;
BEGIN

_RetNodeID := Find_Node(_NodeID := _NodeID, _Descend := FALSE, _Strict := TRUE, _Path := '-> FUNCTION_DECLARATION <- RET');

SELECT      CALL.NodeID
INTO STRICT _CallNodeID
FROM (
    SELECT Edges.ParentNodeID AS NodeID
    FROM Edges
    WHERE Edges.ChildNodeID  = _RetNodeID
    AND   Edges.DeathPhaseID IS NULL
    ORDER BY Edges.EdgeID DESC
    LIMIT 1
) AS CALL
INNER JOIN Nodes     ON Nodes.NodeID         = CALL.NodeID
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
WHERE Nodes.DeathPhaseID IS NULL
AND   NodeTypes.NodeType = 'CALL';

SELECT array_agg(ParentNodeID ORDER BY EdgeID)
INTO STRICT _CopyFromNodeIDs
FROM (
    SELECT EdgeID, ParentNodeID FROM Edges
    WHERE ChildNodeID = _CallNodeID
    AND DeathPhaseID IS NULL
    ORDER BY EdgeID
    OFFSET 1
) AS X;

RAISE NOTICE 'ENTER_STORE_ARGS NodeID % _CopyFromNodeIDs %', _NodeID, _CopyFromNodeIDs;

SELECT array_agg(ParentNodeID ORDER BY EdgeID)
INTO STRICT _CopyToNodeIDs 
FROM Edges
WHERE ChildNodeID = _NodeID
AND DeathPhaseID IS NULL;

RAISE NOTICE 'ENTER_STORE_ARGS NodeID % _CopyToNodeIDs %', _NodeID, _CopyToNodeIDs;

IF  _CopyFromNodeIDs IS NULL
AND _CopyToNodeIDs   IS NULL
THEN
    -- No args
    RETURN;
END IF;

IF array_length(_CopyFromNodeIDs,1) IS DISTINCT FROM array_length(_CopyToNodeIDs,1) THEN
    RAISE EXCEPTION 'Number of function arguments differ between call args and the declared functions args: NodeID % CallNodeID % CopyFromNodeIDs % CopyToNodeIDs %', _NodeID, _CallNodeID, _CopyFromNodeIDs, _CopyToNodeIDs;
END IF;

FOR _i IN 1..array_length(_CopyFromNodeIDs,1) LOOP
    IF (SELECT TerminalType FROM Nodes WHERE NodeID = _CopyFromNodeIDs[_i]) IS NOT NULL THEN
        PERFORM Copy_Node(_FromNodeID := _CopyFromNodeIDs[_i], _ToNodeID := _CopyToNodeIDs[_i]);
    ELSE
        _ClonedNodeID := Clone_Node(_NodeID := _CopyFromNodeIDs[_i]);
        UPDATE Edges SET ChildNodeID  = _ClonedNodeID WHERE ChildNodeID  = _CopyToNodeIDs[_i] AND DeathPhaseID IS NULL;
        UPDATE Edges SET ParentNodeID = _ClonedNodeID WHERE ParentNodeID = _CopyToNodeIDs[_i] AND DeathPhaseID IS NULL;
        PERFORM Kill_Clone(_CopyToNodeIDs[_i]);
    END IF;
END LOOP;

RETURN;
END;
$$;
