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

_FieldNodeID := Get_Field(
    _InstanceNodeID := _InstanceNodeID,
    _Identifier     := _Identifier
);

PERFORM Copy_Node(
    _FromNodeID := _FieldNodeID,
    _ToNodeID   := _NodeID
);

RETURN;
END;
$$;
