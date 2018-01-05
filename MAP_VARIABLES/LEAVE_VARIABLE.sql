CREATE OR REPLACE FUNCTION "MAP_VARIABLES"."LEAVE_VARIABLE"(_NodeID integer)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_VariableNodeID integer;
BEGIN

-- If there is a variable declared with the same name at the same scope level,
_VariableNodeID := Resolve(_NodeID, Node_Name(_NodeID));
IF Declared(_VariableNodeID) = Declared(_NodeID)
-- or if there is a duplicate parameter:
OR Node_Type(Child(_NodeID)) = 'PARAMETERS' AND EXISTS (
    SELECT 1
    FROM Edges
    INNER JOIN Nodes ON Nodes.NodeID = Edges.ParentNodeID
    WHERE Edges.EdgeID            < Edge(_NodeID,Child(_NodeID))
    AND   Edges.ChildNodeID       = Child(_NodeID)
    AND   Node_Name(Nodes.NodeID) = Node_Name(_NodeID)
    AND   Edges.DeathPhaseID      IS NULL
    AND   Nodes.DeathPhaseID      IS NULL
)
THEN
    PERFORM Error(
        _NodeID    := _NodeID,
        _ErrorType := CASE WHEN Global(_NodeID) THEN 'REDECLARED_GLOBAL_VARIABLE' ELSE 'REDECLARED_VARIABLE' END,
        _ErrorInfo := hstore(ARRAY[
            ['VariableName', Node_Name(_NodeID)::text],
            ['VariableNodeID', _VariableNodeID::text]
        ])
    );
END IF;

PERFORM Set_Walkable(_NodeID, FALSE);
RETURN;
END;
$$;
