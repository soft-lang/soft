CREATE OR REPLACE FUNCTION "EVAL"."LEAVE_DECLARATION"(_NodeID integer)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_ParentNodes   integer[];
_NumArgs       integer;
_FromNodeID    integer;
_ToNodeID      integer;
_ClonedNodeID  integer;
_ScopeNodeID   integer;
_EnvironmentID integer;
_OK            boolean;
BEGIN

SELECT array_agg(ParentNodeID ORDER BY EdgeID)
INTO STRICT _ParentNodes
FROM Edges
WHERE ChildNodeID = _NodeID
AND DeathPhaseID IS NULL;

_NumArgs := array_length(_ParentNodes, 1);

_ToNodeID   := _ParentNodes[1];
_FromNodeID := _ParentNodes[2];

_ScopeNodeID := Find_Node(_NodeID := _NodeID, _Descend := TRUE, _Strict := FALSE, _Paths := ARRAY['-> FOR_BODY', '-> WHILE_BODY']);

IF    Closure(_ToNodeID)
AND Node_Type(_ToNodeID) = 'VARIABLE'
THEN
    SELECT EnvironmentID INTO _EnvironmentID FROM Environments WHERE ScopeNodeID = _ScopeNodeID;
    IF NOT FOUND THEN
        _EnvironmentID := New_Environment(_ScopeNodeID);
    END IF;
    PERFORM Set_Reference_Node(_ReferenceNodeID := NULL, _NodeID := _ToNodeID);
    _ClonedNodeID := Clone(_ToNodeID, _EnvironmentID := _EnvironmentID);
    PERFORM Set_Reference_Node(_ReferenceNodeID := _ClonedNodeID, _NodeID := _ToNodeID);
    _ToNodeID := _ClonedNodeID;
ELSIF Closure(_FromNodeID)
AND Node_Type(_FromNodeID) = 'FUNCTION_DECLARATION'
THEN
    PERFORM Kill_Edge(EdgeID) FROM (
        SELECT Edge(CallNodeID, RetNodeID) AS EdgeID
        FROM (
            SELECT
                CallNodeID,
                Child(CallNodeID, 'RET') AS RetNodeID
            FROM (
                SELECT ChildNodeID AS CallNodeID
                FROM Edges
                WHERE ParentNodeID = _ToNodeID
                AND   DeathPhaseID IS NULL
                AND   Node_Type(ChildNodeID) = 'CALL'
            ) AS Q1
        ) AS Q2
        WHERE CallNodeID IS NOT NULL
        AND   RetNodeID  IS NOT NULL
    ) AS Q3;

    SELECT EnvironmentID INTO STRICT _EnvironmentID FROM Environments WHERE ScopeNodeID = _ScopeNodeID;
    PERFORM Set_Reference_Node(_ReferenceNodeID := NULL, _NodeID := _FromNodeID);
    _ClonedNodeID := Clone(_FromNodeID, _EnvironmentID := _EnvironmentID);
    PERFORM Set_Reference_Node(_ReferenceNodeID := _ClonedNodeID, _NodeID := _FromNodeID);
    _FromNodeID := _ClonedNodeID;
END IF;

IF _NumArgs = 1 THEN
    -- Variable declaration only, no assignment of value to it
    RETURN;
ELSIF _NumArgs IS DISTINCT FROM 2 THEN
    RAISE EXCEPTION 'Declaration does not have exactly two parent nodes NodeID % ParentNodes %', _NodeID, _ParentNodes;
END IF;

PERFORM Copy_Node(
    _FromNodeID := Dereference(_FromNodeID),
    _ToNodeID   := _ToNodeID
);

RETURN;
END;
$$;
