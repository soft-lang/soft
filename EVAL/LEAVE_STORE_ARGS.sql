CREATE OR REPLACE FUNCTION "EVAL"."LEAVE_STORE_ARGS"(_NodeID integer) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_FunctionArgsNodeID integer;
_CopyFromNodeIDs integer[];
_CopyToNodeIDs integer[];
_OK boolean;
BEGIN
_FunctionArgsNodeID := Find_Node(_NodeID := _NodeID, _Descend := FALSE, _Strict := TRUE, _Path := '-> FUNCTION_DECLARATION <- RET <- CALL <- ARGS');
SELECT array_agg(ParentNodeID ORDER BY EdgeID) INTO STRICT _CopyFromNodeIDs FROM Edges WHERE ChildNodeID = _FunctionArgsNodeID;
SELECT array_agg(ParentNodeID ORDER BY EdgeID) INTO STRICT _CopyToNodeIDs   FROM Edges WHERE ChildNodeID = _NodeID;
IF (array_length(_CopyFromNodeIDs,1) = array_length(_CopyToNodeIDs,1)) IS NOT TRUE THEN
    RAISE EXCEPTION 'Number of function arguments differ between call args and the declared functions args: CurrentNodeID % FunctionArgsNodeID % CopyFromNodeIDs % CopyToNodeIDs %', _CurrentNodeID, _FunctionArgsNodeID, _CopyFromNodeIDs, _CopyToNodeIDs;
END IF;
FOR _i IN 1..array_length(_CopyFromNodeIDs,1) LOOP
    RAISE NOTICE 'Copying node % to %', _CopyFromNodeIDs[_i], _CopyToNodeIDs[_i];
    PERFORM Copy_Node(_CopyFromNodeIDs[_i], _CopyToNodeIDs[_i]);
END LOOP;
RETURN;
END;
$$;
