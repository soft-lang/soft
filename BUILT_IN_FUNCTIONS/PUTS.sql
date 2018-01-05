CREATE OR REPLACE FUNCTION "BUILT_IN_FUNCTIONS"."PUTS"(_NodeID integer)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_ParentNodeID integer;
BEGIN
FOR   _ParentNodeID IN
SELECT ParentNodeID FROM Edges
WHERE ChildNodeID = Parent(_NodeID,'ARGUMENTS')
AND DeathPhaseID IS NULL
ORDER BY EdgeID
LOOP
    PERFORM Print_Node(_ParentNodeID);
END LOOP;
PERFORM Set_Node_Value(_NodeID, 'nil'::regtype, 'nil');
RETURN;
END;
$$;
