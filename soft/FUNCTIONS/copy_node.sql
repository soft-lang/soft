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
    IF Out_Of_Scope(_FromNodeID := Dereference(_FromNodeID), _ToNodeID := _ToNodeID) THEN
        -- If the node to which we will copy to is out of scope,
        -- all the nodes in the from node must be captured by value,
        -- since you cannot refer to nodes in an inner scope
        -- from an outer scope.
        _VariableBinding := 'CAPTURE_BY_VALUE';
    END IF;
    SELECT EnvironmentID INTO STRICT _EnvironmentID FROM Nodes WHERE NodeID = _ToNodeID;
    _ClonedNodeID := Clone_Node(_NodeID := Dereference(_FromNodeID), _VariableBinding := _VariableBinding, _EnvironmentID := _EnvironmentID);
    UPDATE Edges SET ChildNodeID  = _ClonedNodeID WHERE ChildNodeID  = _ToNodeID AND DeathPhaseID IS NULL;
    UPDATE Edges SET ParentNodeID = _ClonedNodeID WHERE ParentNodeID = _ToNodeID AND DeathPhaseID IS NULL;
    PERFORM Kill_Clone(_ToNodeID);
END IF;

PERFORM Log(
    _NodeID   := _FromNodeID,
    _Severity := 'DEBUG3',
    _Message  := format('Copied node %s to %s', Colorize(Node(_FromNodeID),'CYAN'), Colorize(Node(_ToNodeID),'CYAN'))
);

RETURN TRUE;
END;
$$;
