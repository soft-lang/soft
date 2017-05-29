CREATE OR REPLACE FUNCTION "EVAL"."LEAVE_IF_STATEMENT"(_NodeID integer, _IfExpression boolean DEFAULT FALSE) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID           integer;
_ConditionNodeID     integer;
_ConditionNodeType   regtype;
_ConditionNodeValue  text;
_TrueBranchNodeID    integer;
_TrueBranchReturning boolean;
_ElseBranchNodeID    integer;
_ElseBranchReturning boolean;
_Condition           boolean;
_OK                  boolean;
BEGIN

SELECT
    IfNode.ProgramID,
    ConditionNode.NodeID,
    ConditionNode.TerminalType,
    ConditionNode.TerminalValue,
    TrueBranch.NodeID,
    TrueBranch.Walkable,
    ElseBranch.NodeID,
    ElseBranch.Walkable
INTO STRICT
    _ProgramID,
    _ConditionNodeID,
    _ConditionNodeType,
    _ConditionNodeValue,
    _TrueBranchNodeID,
    _TrueBranchReturning,
    _ElseBranchNodeID,
    _ElseBranchReturning
FROM (
    SELECT array_agg(ParentNodeID ORDER BY EdgeID) AS ParentNodes
    FROM Edges
    WHERE ChildNodeID = _NodeID
    AND DeathPhaseID IS NULL
    HAVING array_length(array_agg(ParentNodeID ORDER BY EdgeID),1) BETWEEN 2 AND 3
) AS E
INNER JOIN Nodes AS IfNode        ON IfNode.NodeID        = _NodeID
INNER JOIN Nodes AS ConditionNode ON ConditionNode.NodeID = E.ParentNodes[1]
INNER JOIN Nodes AS TrueBranch    ON TrueBranch.NodeID    = E.ParentNodes[2]
LEFT  JOIN Nodes AS ElseBranch    ON ElseBranch.NodeID    = E.ParentNodes[3];

IF _ConditionNodeType <> 'boolean'::regtype THEN
    RAISE EXCEPTION 'NodeID % ConditionNodeID % If condition expression is not a boolean value but of type "%"', _NodeID, _ConditionNodeID, _ConditionNodeType;
END IF;

_Condition := _ConditionNodeValue::boolean;

IF    _TrueBranchReturning IS TRUE
AND   _ElseBranchReturning IS NOT TRUE
THEN
    PERFORM Log(
        _NodeID   := _NodeID,
        _Severity := 'DEBUG3',
        _Message  := format('Returning from true branch %s', Colorize(Node(_TrueBranchNodeID), 'CYAN'))
    );
    PERFORM Set_Walkable(_TrueBranchNodeID, FALSE);
    IF _IfExpression THEN
        PERFORM Copy_Node(_FromNodeID := _TrueBranchNodeID, _ToNodeID := _NodeID);
    END IF;

ELSIF _TrueBranchReturning IS FALSE
AND   _ElseBranchReturning IS TRUE
THEN
    PERFORM Log(
        _NodeID   := _NodeID,
        _Severity := 'DEBUG3',
        _Message  := format('Returning from else branch %s', Colorize(Node(_ElseBranchNodeID), 'CYAN'))
    );
    PERFORM Set_Walkable(_ElseBranchNodeID, FALSE);
    IF _IfExpression THEN
        PERFORM Copy_Node(_FromNodeID := _ElseBranchNodeID, _ToNodeID := _NodeID);
    END IF;

ELSIF _Condition           IS TRUE
AND   _TrueBranchReturning IS FALSE
AND   _ElseBranchReturning IS NOT TRUE
THEN
    PERFORM Log(
        _NodeID   := _NodeID,
        _Severity := 'DEBUG3',
        _Message  := format('Goto true branch %s', Colorize(Node(_TrueBranchNodeID), 'CYAN'))
    );
    UPDATE Programs SET NodeID = _TrueBranchNodeID WHERE ProgramID = _ProgramID        RETURNING TRUE INTO STRICT _OK;
    PERFORM Set_Walkable(_TrueBranchNodeID, TRUE);

ELSIF _Condition           IS NOT TRUE
AND   _TrueBranchReturning IS FALSE
AND   _ElseBranchReturning IS NULL
THEN
    PERFORM Log(
        _NodeID   := _NodeID,
        _Severity := 'DEBUG3',
        _Message  := format('No else branch, skipping ahead')
    );

ELSIF _Condition           IS NOT TRUE
AND   _TrueBranchReturning IS FALSE
AND   _ElseBranchReturning IS FALSE
THEN
    PERFORM Log(
        _NodeID   := _NodeID,
        _Severity := 'DEBUG3',
        _Message  := format('Goto else branch %s', Colorize(Node(_ElseBranchNodeID), 'CYAN'))
    );
    UPDATE Programs SET NodeID = _ElseBranchNodeID WHERE ProgramID = _ProgramID RETURNING TRUE INTO STRICT _OK;
    PERFORM Set_Walkable(_ElseBranchNodeID, TRUE);

ELSE
    RAISE EXCEPTION 'Invalid state of if statement: NodeID % Condition % TrueBranchReturning % ElseBranchReturning %', _NodeID, _Condition, _TrueBranchReturning, _ElseBranchReturning;
END IF;

RETURN;
END;
$$;
