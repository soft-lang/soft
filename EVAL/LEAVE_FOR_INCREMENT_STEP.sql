CREATE OR REPLACE FUNCTION "EVAL"."LEAVE_FOR_INCREMENT_STEP"(_NodeID integer)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_ExitConditionNodeID integer;
BEGIN
_ExitConditionNodeID := Find_Node(_NodeID := _NodeID, _Descend := FALSE, _Strict := TRUE, _Path := '-> FOR_STATEMENT <- FOR_EXIT_CONDITION');
PERFORM Set_Program_Node(_ExitConditionNodeID, 'ENTER');
RETURN;
END;
$$;
