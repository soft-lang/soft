CREATE OR REPLACE FUNCTION "EVAL"."ENTER_THIS"(_NodeID integer)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
BEGIN

PERFORM Set_Reference_Node(
    _ReferenceNodeID := Find_Node(
        _NodeID  := _NodeID,
        _Descend := TRUE,
        _Strict  := TRUE,
        _Path    := '-> CLASS_DECLARATION'
    ),
    _NodeID := _NodeID
);
RETURN;
END;
$$;
