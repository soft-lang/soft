CREATE OR REPLACE FUNCTION "EVAL"."ENTER_SUPER"(_NodeID integer)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_SuperClassNodeID integer;
_SuperNodeID      integer;
_OK               boolean;
BEGIN
_SuperClassNodeID := Parent(Find_Node(
    _NodeID    := _NodeID,
    _Descend   := TRUE,
    _Strict    := TRUE,
    _Path      := '-> CLASS_DECLARATION',
    _ErrorType := 'SUPER_OUTSIDE_CLASS'
),'SUPERCLASS');

_SuperNodeID := Parent(_SuperClassNodeID);

IF _SuperNodeID IS NULL THEN
    RAISE EXCEPTION 'Cannot find super class node at NodeID %', _NodeID;
END IF;

IF Node_Name(_SuperNodeID) IS NULL THEN
    -- No instance of the super class yet,
    -- so we need to create a new instance.

    PERFORM Kill_Edge(Edge(_SuperNodeID, _SuperClassNodeID));
    _SuperNodeID := Clone(_SuperNodeID);

    UPDATE Nodes
    SET NodeName = Node_Name(_SuperClassNodeID)
    WHERE NodeID = _SuperNodeID
    RETURNING TRUE INTO STRICT _OK;

    PERFORM New_Edge(_SuperNodeID, _SuperClassNodeID);
END IF;

PERFORM Set_Reference_Node(
    _ReferenceNodeID := _SuperNodeID,
    _NodeID          := _NodeID
);
RETURN;
END;
$$;
