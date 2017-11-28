CREATE OR REPLACE FUNCTION "EVAL"."LEAVE_IDENTIFIER"(_NodeID integer)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID              integer;
_Walkable               boolean;
_RetNodeID              integer;
_RetEdgeID              integer;
_NextNodeID             integer;
_DeclarationNodeID      integer;
_InstanceNodeID         integer;
_FieldNodeID            integer;
_AllocaNodeID           integer;
_VariableNodeID         integer;
_ReturningCall          boolean;
_NodeType               text;
_ImplementationFunction text;
_EnvironmentID          integer;
_Identifier             text;
_LanguageID             integer;
_ParentNodeIDs          integer[];
_OK                     boolean;
BEGIN

_InstanceNodeID := Dereference(Find_Node(
    _NodeID  := _NodeID,
    _Descend := FALSE,
    _Strict  := FALSE,
    _Path    := '-> CALL -> GET <- VARIABLE'
));

IF _InstanceNodeID IS NULL THEN
    RETURN;
END IF;

SELECT
    Nodes.PrimitiveValue,
    NodeTypes.LanguageID
INTO STRICT
    _Identifier,
    _LanguageID
FROM Nodes
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
WHERE Nodes.NodeID = _NodeID
AND   Nodes.DeathPhaseID IS NULL;

IF Node_Type(_InstanceNodeID) IS DISTINCT FROM 'CLASS_DECLARATION' THEN
    RAISE EXCEPTION 'NodeID % is not a CLASS_DECLARATION', _InstanceNodeID;
END IF;
SELECT array_agg(ParentNodeID ORDER BY ParentNodeID)
INTO _ParentNodeIDs
FROM Edges
WHERE ChildNodeID = _InstanceNodeID
AND   DeathPhaseID IS NULL;
IF array_length(_ParentNodeIDs,1) % 2 <> 0 THEN
    RAISE EXCEPTION 'Uneven parent nodes % to class NodeID %', _ParentNodeIDs, _InstanceNodeID;
END IF;
FOR _i IN 1..array_length(_ParentNodeIDs,1)/2 LOOP
    _VariableNodeID := _ParentNodeIDs[_i*2-1];
    _FieldNodeID    := _ParentNodeIDs[_i*2];
    IF Node_Type(_VariableNodeID) IS DISTINCT FROM 'VARIABLE' THEN
        RAISE EXCEPTION 'Parent to class % is not VARIABLE but %', _InstanceNodeID, Node_Type(_VariableNodeID);
    END IF;
    IF Primitive_Value(_VariableNodeID) = _Identifier THEN
        PERFORM Log(
            _NodeID   := _NodeID,
            _Severity := 'DEBUG5',
            _Message  := format('Resolved field %s to %s', Colorize(_Identifier, 'GREEN'), Node(_FieldNodeID))
        );
        PERFORM Copy_Node(
            _FromNodeID := _FieldNodeID,
            _ToNodeID   := _NodeID
        );
        RETURN;
    END IF;
END LOOP;

RETURN;
END;
$$;
