CREATE OR REPLACE FUNCTION "EVAL"."LEAVE_PROGRAM"(_NodeID integer) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID        integer;
_StatementsNodeID integer;
_LastNodeID       integer;
_AllocaNodeID     integer;
_VariableNodeID   integer;
_OK               boolean;
BEGIN

SELECT ProgramID INTO STRICT _ProgramID FROM Nodes WHERE NodeID = _NodeID;

_StatementsNodeID := Find_Node(_NodeID := _NodeID, _Descend := FALSE, _Strict := TRUE, _Path := '<- STATEMENTS');

SELECT     ParentNodeID
INTO STRICT _LastNodeID
FROM Edges
WHERE ChildNodeID = _StatementsNodeID
AND DeathPhaseID IS NULL
ORDER BY EdgeID DESC
LIMIT 1;

PERFORM Log(
    _NodeID   := _NodeID,
    _Severity := 'DEBUG3',
    _Message  := format('Program %s returned with value from %s', Colorize(Node(_NodeID),'CYAN'), Colorize(Node(_LastNodeID),'MAGENTA'))
);

PERFORM Copy_Node(_FromNodeID := _LastNodeID, _ToNodeID := _NodeID);

_AllocaNodeID := Find_Node(_NodeID := _NodeID, _Descend := FALSE, _Strict := TRUE, _Path := '<- ALLOCA');

FOR _VariableNodeID IN
SELECT ParentNodeID FROM Edges WHERE ChildNodeID = _AllocaNodeID ORDER BY EdgeID
LOOP
    PERFORM Pop_Node(_VariableNodeID);
END LOOP;

RETURN;
END;
$$;
