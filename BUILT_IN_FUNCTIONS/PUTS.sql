CREATE OR REPLACE FUNCTION "BUILT_IN_FUNCTIONS"."PUTS"(_NodeID integer)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_ParentNodeID integer;
BEGIN
FOR   _ParentNodeID IN
SELECT ParentNodeID FROM Edges
WHERE ChildNodeID = _NodeID
AND DeathPhaseID IS NULL
ORDER BY EdgeID
OFFSET 1 -- Skip 'puts' IDENTIFIER node
LOOP
    PERFORM Print_Node(_ParentNodeID);
END LOOP;
PERFORM Set_Node_Value(_NodeID, 'nil'::regtype, 'nil');
RETURN;
END;
$$;
