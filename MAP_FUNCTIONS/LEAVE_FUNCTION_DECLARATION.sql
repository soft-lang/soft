CREATE OR REPLACE FUNCTION "MAP_VARIABLES"."LEAVE_FUNCTION_DECLARATION"(_NodeID integer) RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_LetStatementNodeID integer;
_IdentifierNodeID   integer;
_EdgeID             integer;
_VariableNodeID     integer;
_OK                 boolean;
BEGIN

_LetStatementNodeID := Find_Node(_NodeID := _NodeID, _Descend := FALSE, _Strict := TRUE, _Path := '-> LET_STATEMENT');
_VariableNodeID     := Find_Node(_NodeID := _NodeID, _Descend := FALSE, _Strict := TRUE, _Path := '-> LET_STATEMENT <- VARIABLE');
_IdentifierNodeID   := Find_Node(_NodeID := _NodeID, _Descend := FALSE, _Strict := TRUE, _Path := '-> LET_STATEMENT <- VARIABLE <- IDENTIFIER');

PERFORM Copy_Node(_FromNodeID := _IdentifierNodeID, _ToNodeID := _VariableNodeID);

SELECT Kill_Edge(EdgeID) INTO STRICT _OK FROM Edges WHERE DeathPhaseID IS NULL AND ChildNodeID = _LetStatementNodeID AND ParentNodeID = _VariableNodeID;
SELECT Kill_Edge(EdgeID) INTO STRICT _OK FROM Edges WHERE DeathPhaseID IS NULL AND ChildNodeID = _VariableNodeID AND ParentNodeID = _IdentifierNodeID;
SELECT Set_Edge_Child(_EdgeID := EdgeID, _ChildNodeID := _VariableNodeID) INTO STRICT _OK FROM Edges WHERE DeathPhaseID IS NULL AND ParentNodeID = _NodeID;
SELECT Set_Edge_Parent(_EdgeID := EdgeID, _ParentNodeID := _VariableNodeID) INTO STRICT _OK FROM Edges WHERE DeathPhaseID IS NULL AND ParentNodeID = _LetStatementNodeID;
PERFORM Kill_Node(_LetStatementNodeID);
PERFORM Kill_Node(_IdentifierNodeID);

PERFORM Log(
    _NodeID   := _NodeID,
    _Severity := 'DEBUG2',
    _Message  := format('%s is now declared and can be accessed', Colorize(Node(_VariableNodeID), 'CYAN'))
);

RETURN TRUE;
END;
$$;
