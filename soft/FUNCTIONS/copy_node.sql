CREATE OR REPLACE FUNCTION Copy_Node(_FromNodeID integer, _ToNodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_PrimitiveValue  text;
_ClonedNodeID    integer;
_OK              boolean;
_VariableBinding variablebinding;
_EnvironmentID   integer;
BEGIN

IF (SELECT PrimitiveType FROM Nodes WHERE NodeID = Dereference(_FromNodeID)) IS NOT NULL THEN
    UPDATE Nodes AS CopyTo SET
        PrimitiveType  = CopyFrom.PrimitiveType,
        PrimitiveValue = CopyFrom.PrimitiveValue
    FROM Nodes AS CopyFrom
    WHERE CopyFrom.NodeID = Dereference(_FromNodeID)
    AND     CopyTo.NodeID = _ToNodeID
    RETURNING TRUE INTO STRICT _OK;
ELSE
    UPDATE Nodes SET
        PrimitiveType  = NULL,
        PrimitiveValue = NULL
    WHERE NodeID = _ToNodeID
    RETURNING TRUE INTO STRICT _OK;
    PERFORM Set_Reference_Node(_ReferenceNodeID := _FromNodeID, _NodeID := _ToNodeID);
END IF;

PERFORM Log(
    _NodeID   := _FromNodeID,
    _Severity := 'DEBUG3',
    _Message  := format('Copied node %s to %s', Colorize(Node(_FromNodeID),'CYAN'), Colorize(Node(_ToNodeID),'CYAN'))
);

RETURN TRUE;
END;
$$;
