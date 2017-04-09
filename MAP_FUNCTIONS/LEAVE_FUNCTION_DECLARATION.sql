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

SELECT Kill_Edge(EdgeID) INTO STRICT _OK FROM Edges WHERE DeathPhaseID IS NULL AND ChildNodeID = _LetStatementNodeID AND ParentNodeID = _VariableNodeID;
SELECT Set_Edge_Child(_EdgeID := EdgeID, _ChildNodeID := _VariableNodeID) INTO STRICT _OK FROM Edges WHERE DeathPhaseID IS NULL AND ParentNodeID = _NodeID;
SELECT Set_Edge_Parent(_EdgeID := EdgeID, _ParentNodeID := _VariableNodeID) INTO STRICT _OK FROM Edges WHERE DeathPhaseID IS NULL AND ParentNodeID = _LetStatementNodeID;
PERFORM Kill_Node(_LetStatementNodeID);

PERFORM Set_Node_Type(
    _NodeID     := _VariableNodeID,
    _NodeTypeID := (SELECT NodeTypeID FROM NodeTypes WHERE NodeType = 'FUNCTION_LABEL')
);

PERFORM Log(
    _NodeID   := _NodeID,
    _Severity := 'DEBUG2',
    _Message  := format('%s is now declared and can be accessed', Colorize(Node(_VariableNodeID), 'CYAN'))
);

RETURN TRUE;
END;
$$;
