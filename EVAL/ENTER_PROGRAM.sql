CREATE OR REPLACE FUNCTION "EVAL"."ENTER_PROGRAM"(_NodeID integer) RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_AllocaNodeID   integer;
_VariableNodeID integer;
BEGIN

_AllocaNodeID := Find_Node(_NodeID := _NodeID, _Descend := FALSE, _Strict := TRUE, _Path := '<- ALLOCA');

FOR _VariableNodeID IN
SELECT ParentNodeID FROM Edges WHERE DeathPhaseID IS NULL AND ChildNodeID = _AllocaNodeID ORDER BY EdgeID
LOOP
    PERFORM Push_Node(_VariableNodeID);
END LOOP;

RETURN TRUE;
END;
$$;
