CREATE OR REPLACE FUNCTION "MAP_VARIABLES"."ENTER_THIS"(_NodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_OK boolean;
BEGIN
PERFORM Find_Node(
    _NodeID    := _NodeID,
    _Descend   := TRUE,
    _Strict    := TRUE,
    _Path      := '-> CLASS_DECLARATION',
    _ErrorType := 'THIS_OUTSIDE_CLASS'
);

UPDATE Nodes SET
    PrimitiveValue = NULL,
    PrimitiveType  = NULL
WHERE NodeID = _NodeID
RETURNING TRUE INTO STRICT _OK;
RETURN TRUE;
END;
$$;
