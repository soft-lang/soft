CREATE OR REPLACE FUNCTION "VALIDATE"."ENTER_RETURN_STATEMENT"(_NodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_FunctionNodeID integer;
BEGIN

_FunctionNodeID := Find_Node(
    _NodeID  := _NodeID,
    _Descend := TRUE,
    _Strict  := FALSE,
    _Path    := '-> FUNCTION_DECLARATION'
);
IF _FunctionNodeID IS NULL THEN
    -- Not inside function, returning from program
    RETURN TRUE;
END IF;

IF Node_Type(Child(_FunctionNodeID)) = 'CLASS_DECLARATION'
AND Primitive_Value(Parent(Left(_FunctionNodeID))) = 'init'
THEN
    PERFORM Log(
        _NodeID   := _NodeID,
        _Severity := 'ERROR',
        _Message  := 'Cannot return a value from an initializer.'
    );
    RETURN FALSE;
END IF;

RETURN TRUE;
END;
$$;
