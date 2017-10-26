CREATE OR REPLACE FUNCTION "EVAL"."LEAVE_WHILE_EXIT_CONDITION"(_NodeID integer)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_ConditionExpressionNodeID integer;
_StatementNodeID           integer;
_BodyNodeID                integer;
_Walkable                  boolean;
BEGIN

_StatementNodeID := Find_Node(_NodeID := _NodeID,          _Descend := FALSE, _Strict := TRUE, _Path := '-> WHILE_STATEMENT');
_BodyNodeID      := Find_Node(_NodeID := _StatementNodeID, _Descend := FALSE, _Strict := TRUE, _Path := '<- WHILE_BODY');

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

PERFORM Set_Walkable(_BodyNodeID, _Walkable);

IF _Walkable THEN
    PERFORM Set_Program_Node(_BodyNodeID, 'ENTER');
END IF;

RETURN;
END;
$$;
