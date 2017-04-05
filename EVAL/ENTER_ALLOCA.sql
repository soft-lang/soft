CREATE OR REPLACE FUNCTION "EVAL"."ENTER_ALLOCA"(_NodeID integer) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_VariableNodeID integer;
BEGIN

FOR _VariableNodeID IN
SELECT ParentNodeID FROM Edges WHERE ChildNodeID = _NodeID ORDER BY EdgeID
LOOP
    PERFORM Push_Node(_VariableNodeID);
END LOOP;

RETURN;
END;
$$;
