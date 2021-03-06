CREATE OR REPLACE FUNCTION "EVAL"."LEAVE_WHILE_BODY"(_NodeID integer)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_ExitConditionNodeID integer;
BEGIN
_ExitConditionNodeID := Find_Node(_NodeID := _NodeID, _Descend := FALSE, _Strict := TRUE, _Path := '-> WHILE_STATEMENT <- WHILE_EXIT_CONDITION');
PERFORM Set_Program_Node(_ExitConditionNodeID, 'ENTER');
RETURN;
END;
$$;
