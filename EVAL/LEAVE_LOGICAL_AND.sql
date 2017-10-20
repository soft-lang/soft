CREATE OR REPLACE FUNCTION "EVAL"."LEAVE_LOGICAL_AND"(_NodeID integer)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID               integer;
_LeftConditionNodeID     integer;
_LeftConditionNodeType   regtype;
_LeftConditionNodeValue  text;
_RightConditionNodeID    integer;
_RightConditionNodeType  regtype;
_RightConditionNodeValue text;
_RightConditionEvaluated boolean;
_Condition               boolean;
_OK                      boolean;
BEGIN

SELECT
    ANDNode.ProgramID,
    LeftConditionNode.NodeID,
    Primitive_Type(LeftConditionNode.NodeID),
    Primitive_Value(LeftConditionNode.NodeID),
    RightConditionNode.NodeID,
    Primitive_Type(RightConditionNode.NodeID),
    Primitive_Value(RightConditionNode.NodeID),
    RightConditionNode.Walkable
INTO STRICT
    _ProgramID,
    _LeftConditionNodeID,
    _LeftConditionNodeType,
    _LeftConditionNodeValue,
    _RightConditionNodeID,
    _RightConditionNodeType,
    _RightConditionNodeValue,
    _RightConditionEvaluated
FROM (
    SELECT array_agg(ParentNodeID ORDER BY EdgeID) AS ParentNodes
    FROM Edges
    WHERE ChildNodeID = _NodeID
    AND DeathPhaseID IS NULL
    HAVING array_length(array_agg(ParentNodeID ORDER BY EdgeID),1) = 2
) AS E
INNER JOIN Nodes AS ANDNode            ON ANDNode.NodeID            = _NodeID
INNER JOIN Nodes AS LeftConditionNode  ON LeftConditionNode.NodeID  = E.ParentNodes[1]
INNER JOIN Nodes AS RightConditionNode ON RightConditionNode.NodeID = E.ParentNodes[2];

IF Truthy(_LeftConditionNodeID) IS FALSE
THEN
    PERFORM Log(
        _NodeID   := _NodeID,
        _Severity := 'DEBUG3',
        _Message  := format('Short-circuit AND since left argument is false %s', Colorize(Node(_RightConditionNodeID), 'CYAN'))
    );
    PERFORM Set_Node_Value(
        _NodeID         := _NodeID,
        _PrimitiveType  := _LeftConditionNodeType,
        _PrimitiveValue := _LeftConditionNodeValue
    );
ELSIF _RightConditionEvaluated
AND NOT (Language(_NodeID)).TruthyNonBooleans
AND (_LeftConditionNodeType  <> 'boolean'::regtype
OR   _RightConditionNodeType <> 'boolean'::regtype)
THEN
    RAISE EXCEPTION 'Logical operation requires boolean arguments';
ELSIF NOT _RightConditionEvaluated THEN
    PERFORM Log(
        _NodeID   := _NodeID,
        _Severity := 'DEBUG3',
        _Message  := format('Evaluate right AND argument %s', Colorize(Node(_RightConditionNodeID), 'CYAN'))
    );
    PERFORM Set_Program_Node(_RightConditionNodeID, 'ENTER');
    PERFORM Set_Walkable(_RightConditionNodeID, TRUE);
    RETURN;
ELSIF _RightConditionEvaluated THEN
    PERFORM Set_Node_Value(
        _NodeID         := _NodeID,
        _PrimitiveType  := _RightConditionNodeType,
        _PrimitiveValue := _RightConditionNodeValue
    );
ELSE
    RAISE EXCEPTION 'How did we end up here?! RightConditionEvaluated %', _RightConditionEvaluated;
END IF;

IF _RightConditionEvaluated THEN
    PERFORM Set_Walkable(_RightConditionNodeID, FALSE);
END IF;

RETURN;
END;
$$;
