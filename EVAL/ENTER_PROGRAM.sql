CREATE OR REPLACE FUNCTION "EVAL"."ENTER_PROGRAM"(_NodeID integer) RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_AllocaNodeID   integer;
_VariableNodeID integer;
BEGIN

_AllocaNodeID := Find_Node(_NodeID := _NodeID, _Descend := FALSE, _Strict := TRUE, _Path := '<- ALLOCA');

RETURN TRUE;
END;
$$;
