CREATE OR REPLACE FUNCTION "EVAL"."LEAVE_FOR_EXIT_CONDITION"(_NodeID integer)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_ConditionExpressionNodeID integer;
_ForStatementNodeID        integer;
_IncrementStepNodeID       integer;
_ForBodyNodeID             integer;
_Walkable                  boolean;
BEGIN

_ForStatementNodeID  := Find_Node(_NodeID := _NodeID,             _Descend := FALSE, _Strict := TRUE, _Path := '-> FOR_STATEMENT');
_IncrementStepNodeID := Find_Node(_NodeID := _ForStatementNodeID, _Descend := FALSE, _Strict := TRUE, _Path := '<- FOR_INCREMENT_STEP');
_ForBodyNodeID       := Find_Node(_NodeID := _ForStatementNodeID, _Descend := FALSE, _Strict := TRUE, _Path := '<- FOR_BODY');

SELECT ParentNodeID
INTO    _ConditionExpressionNodeID
FROM Edges
WHERE ChildNodeID = _NodeID
AND DeathPhaseID IS NULL;
IF FOUND THEN
    PERFORM Set_Reference_Node(
        _ReferenceNodeID := _ConditionExpressionNodeID,
        _NodeID          := _NodeID
    );
    _Walkable := Truthy(_ConditionExpressionNodeID);
ELSE
    -- Empty exit condition
    _Walkable := TRUE;
END IF;

PERFORM Set_Walkable(_IncrementStepNodeID, _Walkable);
PERFORM Set_Walkable(_ForBodyNodeID,       _Walkable);

IF _Walkable THEN
    PERFORM Set_Program_Node(_ForBodyNodeID, 'ENTER');
END IF;

RETURN;
END;
$$;
