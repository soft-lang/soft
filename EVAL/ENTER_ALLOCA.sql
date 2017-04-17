CREATE OR REPLACE FUNCTION "EVAL"."ENTER_ALLOCA"(_NodeID integer) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_VariableNodeID integer;
_ProgramID      integer;
_ChildNodeID    integer;
_OK             boolean;
BEGIN

FOR _VariableNodeID IN
SELECT ParentNodeID FROM Edges WHERE ChildNodeID = _NodeID ORDER BY EdgeID
LOOP
    PERFORM Push_Node(_VariableNodeID);
END LOOP;

SELECT ProgramID, ChildNodeID INTO STRICT _ProgramID, _ChildNodeID FROM Edges WHERE DeathPhaseID IS NULL AND ParentNodeID = _NodeID;

UPDATE Programs SET NodeID = _ChildNodeID WHERE ProgramID = _ProgramID AND NodeID = _NodeID RETURNING TRUE INTO STRICT _OK;

RETURN;
END;
$$;
