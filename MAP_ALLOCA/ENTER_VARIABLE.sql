CREATE OR REPLACE FUNCTION "MAP_ALLOCA"."ENTER_VARIABLE"(_NodeID integer) RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID    integer;
_AllocaNodeID integer;
_OK           boolean;
BEGIN

IF Find_Node(_NodeID := _NodeID, _Descend := FALSE, _Strict := FALSE, _Path := '-> LET_STATEMENT <- FUNCTION_DECLARATION') IS NOT NULL
THEN
    RETURN FALSE;
END IF;

SELECT ProgramID INTO STRICT _ProgramID FROM Nodes WHERE NodeID = _NodeID;

_AllocaNodeID := Find_Node(_NodeID := _NodeID, _Descend := TRUE, _Strict := TRUE, _Path := '<- ALLOCA');

PERFORM New_Edge(
    _ProgramID    := _ProgramID,
    _ParentNodeID := _NodeID,
    _ChildNodeID  := _AllocaNodeID
);

RETURN TRUE;
END;
$$;
