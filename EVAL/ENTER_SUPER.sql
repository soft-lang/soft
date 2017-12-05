CREATE OR REPLACE FUNCTION "EVAL"."ENTER_SUPER"(_NodeID integer)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_SuperClassNodeID integer;
BEGIN
_SuperClassNodeID := Parent(Parent(Find_Node(
    _NodeID  := _NodeID,
    _Descend := TRUE,
    _Strict  := TRUE,
    _Path    := '-> CLASS_DECLARATION'
),'SUPER_CLASS'));

IF _SuperClassNodeID IS NULL THEN
    RAISE EXCEPTION 'Cannot find super class node at NodeID %', _NodeID;
END IF;

PERFORM Set_Reference_Node(
    _ReferenceNodeID := _SuperClassNodeID,
    _NodeID          := _NodeID
);
RETURN;
END;
$$;
