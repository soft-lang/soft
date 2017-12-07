CREATE OR REPLACE FUNCTION "MAP_VARIABLES"."ENTER_SUPER"(_NodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_ClassNodeID integer;
_OK          boolean;
BEGIN
_ClassNodeID := Find_Node(
    _NodeID    := _NodeID,
    _Descend   := TRUE,
    _Strict    := TRUE,
    _Path      := '-> CLASS_DECLARATION',
    _ErrorType := 'SUPER_OUTSIDE_CLASS'
);
IF _ClassNodeID IS NULL THEN
    RETURN FALSE;
END IF;

IF Parent(_ClassNodeID,'SUPERCLASS') IS NULL THEN
    PERFORM Error(
        _NodeID := _NodeID,
        _ErrorType := 'SUPER_IN_CLASS_WITHOUT_SUPERCLASS'
    );
    RETURN FALSE;
END IF;

UPDATE Nodes SET
    PrimitiveValue = NULL,
    PrimitiveType  = NULL
WHERE NodeID = _NodeID
RETURNING TRUE INTO STRICT _OK;
RETURN TRUE;
END;
$$;
