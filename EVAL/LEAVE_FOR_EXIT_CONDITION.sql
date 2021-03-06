CREATE OR REPLACE FUNCTION "EVAL"."LEAVE_FOR_EXIT_CONDITION"(_NodeID integer)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_ConditionExpressionNodeID integer;
_StatementNodeID           integer;
_IncrementStepNodeID       integer;
_BodyNodeID                integer;
_Walkable                  boolean;
BEGIN

_StatementNodeID     := Find_Node(_NodeID := _NodeID,          _Descend := FALSE, _Strict := TRUE, _Path := '-> FOR_STATEMENT');
_IncrementStepNodeID := Find_Node(_NodeID := _StatementNodeID, _Descend := FALSE, _Strict := TRUE, _Path := '<- FOR_INCREMENT_STEP');
_BodyNodeID          := Find_Node(_NodeID := _StatementNodeID, _Descend := FALSE, _Strict := TRUE, _Path := '<- FOR_BODY');

SELECT             ParentNodeID
INTO _ConditionExpressionNodeID
FROM Edges
WHERE ChildNodeID = _NodeID
AND DeathPhaseID IS NULL;
IF FOUND THEN
    PERFORM Set_Reference_Node(
        _ReferenceNodeID := _ConditionExpressionNodeID,
        _NodeID          := _NodeID
    );
    _Walkable := Truthy(_ConditionExpressionNodeID);
ELSIF Primitive_Value(_NodeID) IS NOT NULL THEN
    -- Hard-coded primitive exit condition, e.g. for (; false;)
    _Walkable := Truthy(_NodeID);
ELSE
    -- Empty exit condition, e.g. for(;;)
    _Walkable := TRUE;
END IF;

PERFORM Set_Walkable(_IncrementStepNodeID, _Walkable);
PERFORM Set_Walkable(_BodyNodeID,          _Walkable);

IF _Walkable THEN
    PERFORM Set_Program_Node(_BodyNodeID, 'ENTER');
END IF;

RETURN;
END;
$$;
