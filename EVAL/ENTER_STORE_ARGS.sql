CREATE OR REPLACE FUNCTION "EVAL"."ENTER_STORE_ARGS"(_NodeID integer) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_CallNodeID integer;
_CopyFromNodeIDs integer[];
_CopyToNodeIDs integer[];
_OK boolean;
BEGIN
_CallNodeID := Find_Node(_NodeID := _NodeID, _Descend := FALSE, _Strict := TRUE, _Path := '-> FUNCTION_DECLARATION <- RET <- CALL');

SELECT array_agg(ParentNodeID ORDER BY EdgeID)
INTO STRICT _CopyFromNodeIDs
FROM (
    SELECT EdgeID, ParentNodeID FROM Edges
    WHERE ChildNodeID = _CallNodeID
    AND DeathPhaseID IS NULL
    ORDER BY EdgeID
    OFFSET 1
) AS X;

SELECT array_agg(ParentNodeID ORDER BY EdgeID)
INTO STRICT _CopyToNodeIDs 
FROM Edges
WHERE ChildNodeID = _NodeID
AND DeathPhaseID IS NULL;

IF (array_length(_CopyFromNodeIDs,1) = array_length(_CopyToNodeIDs,1)) IS NOT TRUE THEN
    RAISE EXCEPTION 'Number of function arguments differ between call args and the declared functions args: NodeID % CallNodeID % CopyFromNodeIDs % CopyToNodeIDs %', _NodeID, _CallNodeID, _CopyFromNodeIDs, _CopyToNodeIDs;
END IF;

FOR _i IN 1..array_length(_CopyFromNodeIDs,1) LOOP
    PERFORM Copy_Node(_CopyFromNodeIDs[_i], _CopyToNodeIDs[_i]);
END LOOP;

RETURN;
END;
$$;
