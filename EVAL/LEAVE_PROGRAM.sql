CREATE OR REPLACE FUNCTION "EVAL"."LEAVE_PROGRAM"(_NodeID integer) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_AllocaNodeID   integer;
_VariableNodeID integer;
BEGIN

_AllocaNodeID := Find_Node(_NodeID := _NodeID, _Descend := FALSE, _Strict := TRUE, _Path := '<- ALLOCA');

FOR _VariableNodeID IN
SELECT ParentNodeID FROM Edges WHERE ChildNodeID = _AllocaNodeID ORDER BY EdgeID
LOOP
    PERFORM Pop_Node(_VariableNodeID);
END LOOP;

RETURN;
END;
$$;
