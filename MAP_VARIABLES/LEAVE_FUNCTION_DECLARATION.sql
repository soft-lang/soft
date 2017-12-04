CREATE OR REPLACE FUNCTION "MAP_VARIABLES"."LEAVE_FUNCTION_DECLARATION"(_NodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_OK boolean;
BEGIN
PERFORM Set_Walkable(_NodeID, FALSE);

IF Find_Node(_NodeID := _NodeID, _Descend := FALSE, _Strict := FALSE, _Path := '-> DECLARATION -> STATEMENTS -> PROGRAM') IS NULL THEN
    -- Not a globally declared function, so might be a closure.
    UPDATE Nodes
    SET Closure = TRUE
    FROM Get_Closure_Nodes(_NodeID) AS CapturedVariableNodeID
    WHERE Nodes.NodeID = CapturedVariableNodeID;
    IF FOUND THEN
        UPDATE Nodes
        SET Closure = TRUE
        WHERE NodeID = _NodeID
        RETURNING TRUE INTO STRICT _OK;
    END IF;
END IF;

RETURN TRUE;
END;
$$;
