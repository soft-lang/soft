CREATE OR REPLACE FUNCTION "EVAL"."ENTER_SUPER"(_NodeID integer)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_SuperClassNodeID       integer;
_ClassDeclarationNodeID integer;
_SuperNodeID            integer;
_OK                     boolean;
BEGIN
_SuperClassNodeID := Parent(Find_Node(
    _NodeID    := _NodeID,
    _Descend   := TRUE,
    _Strict    := TRUE,
    _Paths     := ARRAY[
        '-> CLASS_DECLARATION',
        '-> SUPERCLASS'
    ],
    _ErrorType := 'SUPER_OUTSIDE_CLASS'
),'SUPERCLASS');

IF _SuperClassNodeID IS NULL THEN
    RAISE EXCEPTION 'Cannot find super class node at NodeID %', _NodeID;
END IF;

_ClassDeclarationNodeID := Parent(_SuperClassNodeID, 'CLASS_DECLARATION');

IF _ClassDeclarationNodeID IS NOT NULL THEN
    -- No instance of the super class yet,
    -- so we need to create a new instance.
    _SuperClassNodeID := Instantiate_SuperClass(_ClassDeclarationNodeID, _SuperClassNodeID);
END IF;

PERFORM Set_Reference_Node(
    _ReferenceNodeID := _SuperClassNodeID,
    _NodeID          := _NodeID
);
RETURN;
END;
$$;
