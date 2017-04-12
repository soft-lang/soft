CREATE OR REPLACE FUNCTION "EVAL"."LEAVE_CALL"(_NodeID integer) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID                 integer;
_Visited                   integer;
_RetNodeID                 integer;
_FunctionDeclarationNodeID integer;
_RetEdgeID                 integer;
_AllocaNodeID              integer;
_VariableNodeID            integer;
_OK                        boolean;
BEGIN

SELECT ProgramID, Visited INTO STRICT _ProgramID, _Visited FROM Nodes WHERE NodeID = _NodeID;

_FunctionDeclarationNodeID := Find_Node(_NodeID := _NodeID,                    _Descend := FALSE, _Strict := TRUE, _Path := '<- FUNCTION_LABEL <- FUNCTION_DECLARATION');
_RetNodeID                 := Find_Node(_NodeID := _FunctionDeclarationNodeID, _Descend := FALSE, _Strict := TRUE, _Path := '<- RET');

PERFORM Log(
    _NodeID   := _NodeID,
    _Severity := 'DEBUG3',
    _Message  := format('Outgoing function call at %s to %s', Colorize(Node(_NodeID),'CYAN'), Colorize(Node(_FunctionDeclarationNodeID),'MAGENTA'))
);

UPDATE Nodes SET Visited = Visited + 1 WHERE NodeID = _FunctionDeclarationNodeID RETURNING TRUE INTO STRICT _OK;

UPDATE Programs SET NodeID = _FunctionDeclarationNodeID WHERE ProgramID = _ProgramID AND NodeID = _NodeID RETURNING TRUE INTO STRICT _OK;

PERFORM New_Edge(
    _ProgramID    := _ProgramID,
    _ParentNodeID := _NodeID,
    _ChildNodeID  := _RetNodeID
);

RETURN;
END;
$$;
