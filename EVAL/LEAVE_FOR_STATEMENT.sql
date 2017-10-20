CREATE OR REPLACE FUNCTION "EVAL"."LEAVE_FOR_STATEMENT"(_NodeID integer)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_IncrementStepNodeID integer;
BEGIN

_IncrementStepNodeID := Find_Node(_NodeID := _NodeID, _Descend := FALSE, _Strict := TRUE, _Path := '<- FOR_INCREMENT_STEP');
IF (SELECT Walkable FROM Nodes WHERE NodeID = _IncrementStepNodeID) THEN
    PERFORM Set_Program_Node(_IncrementStepNodeID, 'ENTER');
END IF;

RETURN;
END;
$$;
