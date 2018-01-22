CREATE OR REPLACE FUNCTION "OPTIMIZE"."LEAVE_LOOP_BLOCK"(_NodeID integer)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_ParentNodeIDs  integer[];
_Count          bigint;
_Argument       integer;
_ArgumentNodeID integer;
_ProgramID      integer;
_LanguageID     integer;
BEGIN

SELECT array_agg(ParentNodeID ORDER BY EdgeID)
INTO STRICT _ParentNodeIDs
FROM Edges
WHERE ChildNodeID = _NodeID
AND DeathPhaseID IS NULL;

SELECT
    Nodes.ProgramID,
    NodeTypes.LanguageID
INTO STRICT
    _ProgramID,
    _LanguageID
FROM Nodes
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
WHERE Nodes.NodeID = _NodeID;

_Count := array_length(_ParentNodeIDs, 1);

IF Node_Type(_ParentNodeIDs[1])      IS DISTINCT FROM 'JUMP_IF_DATA_ZERO'
OR Node_Type(_ParentNodeIDs[_Count]) IS DISTINCT FROM 'JUMP_IF_DATA_NOT_ZERO'
THEN
    RAISE EXCEPTION 'Invalid loop block, NodeID %', _NodeID;
END IF;

IF _Count = 3 THEN
    IF Node_Type(_ParentNodeIDs[2]) = 'DEC_DATA' THEN
        RAISE NOTICE 'Optimize [-] NodeID %', _NodeID;
        -- Detect pattern: [-]
        PERFORM Change_Node_Type(_NodeID, 'LOOP_BLOCK', 'LOOP_SET_TO_ZERO');

    ELSIF Node_Type(_ParentNodeIDs[2]) = 'INC_PTR' THEN
        RAISE NOTICE 'Optimize [>] NodeID %', _NodeID;
        -- Detect pattern: [>]
        PERFORM Change_Node_Type(_NodeID, 'LOOP_BLOCK', 'LOOP_MOVE_PTR');
        _Argument := COALESCE(Primitive_Value(Parent(_ParentNodeIDs[2], 'ARGUMENT'))::integer, 1);

    ELSIF Node_Type(_ParentNodeIDs[2]) = 'DEC_PTR' THEN
        RAISE NOTICE 'Optimize [<] NodeID %', _NodeID;
        -- Detect pattern: [<]
        PERFORM Change_Node_Type(_NodeID, 'LOOP_BLOCK', 'LOOP_MOVE_PTR');
        _Argument := -COALESCE(Primitive_Value(Parent(_ParentNodeIDs[2], 'ARGUMENT'))::integer, 1);

    ELSE
        RAISE NOTICE 'Cannot optimize NodeID %', _NodeID;
        RETURN;

    END IF;

ELSIF _Count = 6 THEN

    IF  Node_Type(_ParentNodeIDs[2]) = 'DEC_DATA'
    AND Node_Type(_ParentNodeIDs[3]) = 'INC_PTR'
    AND Node_Type(_ParentNodeIDs[4]) = 'INC_DATA'
    AND Node_Type(_ParentNodeIDs[5]) = 'DEC_PTR'
    AND COALESCE(Primitive_Value(Parent(_ParentNodeIDs[3], 'ARGUMENT'))::integer, 1)
    =   COALESCE(Primitive_Value(Parent(_ParentNodeIDs[5], 'ARGUMENT'))::integer, 1)
    THEN
        RAISE NOTICE 'Optimize ->+< NodeID %', _NodeID;
        -- Detect patterns: ->+<
        PERFORM Change_Node_Type(_NodeID, 'LOOP_BLOCK', 'LOOP_MOVE_DATA');
        _Argument := COALESCE(Primitive_Value(Parent(_ParentNodeIDs[3], 'ARGUMENT'))::integer, 1);

    ELSIF Node_Type(_ParentNodeIDs[2]) = 'DEC_DATA'
    AND   Node_Type(_ParentNodeIDs[3]) = 'DEC_PTR'
    AND   Node_Type(_ParentNodeIDs[4]) = 'INC_DATA'
    AND   Node_Type(_ParentNodeIDs[5]) = 'INC_PTR'
    AND   COALESCE(Primitive_Value(Parent(_ParentNodeIDs[3], 'ARGUMENT'))::integer, 1)
    =     COALESCE(Primitive_Value(Parent(_ParentNodeIDs[5], 'ARGUMENT'))::integer, 1)
    THEN
        RAISE NOTICE 'Optimize -<+> NodeID %', _NodeID;
        -- Detect patterns: -<+>
        PERFORM Change_Node_Type(_NodeID, 'LOOP_BLOCK', 'LOOP_MOVE_DATA');
        _Argument := -COALESCE(Primitive_Value(Parent(_ParentNodeIDs[3], 'ARGUMENT'))::integer, 1);

    ELSE
        RAISE NOTICE 'Cannot optimize NodeID %', _NodeID;
        RETURN;

    END IF;

ELSE
    RAISE NOTICE 'Cannot optimize NodeID %', _NodeID;
    RETURN;

END IF;

PERFORM Kill_Edge(EdgeID)
FROM Edges
WHERE (ParentNodeID = ANY(_ParentNodeIDs)
    OR ChildNodeID  = ANY(_ParentNodeIDs))
AND DeathPhaseID IS NULL;

PERFORM Kill_Node(NodeID)
FROM Nodes
WHERE NodeID = ANY(_ParentNodeIDs)
AND DeathPhaseID IS NULL;

PERFORM New_Edge(_ParentNodeID := Data_Node(_NodeID), _ChildNodeID := _NodeID);

IF _Argument IS NOT NULL THEN
    _ArgumentNodeID := New_Node(
        _ProgramID      := _ProgramID,
        _NodeTypeID     := (SELECT NodeTypeID FROM NodeTypes WHERE LanguageID = _LanguageID AND NodeType = 'ARGUMENT'),
        _PrimitiveType  := 'integer',
        _PrimitiveValue := _Argument::text,
        _Walkable       := FALSE
    );
    PERFORM New_Edge(_ParentNodeID := _ArgumentNodeID, _ChildNodeID := _NodeID);
END IF;

RETURN;
END;
$$;
