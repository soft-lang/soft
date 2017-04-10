CREATE OR REPLACE FUNCTION "EVAL"."LEAVE_PROGRAM"(_NodeID integer) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID      integer;
_LastNodeID     integer;
_AllocaNodeID   integer;
_VariableNodeID integer;
_OK             boolean;
BEGIN

SELECT ProgramID INTO STRICT _ProgramID FROM Nodes WHERE NodeID = _NodeID;

SELECT     ParentNodeID
INTO STRICT _LastNodeID
FROM Edges
WHERE ChildNodeID = _NodeID
AND DeathPhaseID IS NULL
ORDER BY EdgeID DESC
OFFSET 1
LIMIT 1;

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
