CREATE OR REPLACE FUNCTION "EVAL"."LEAVE_RETURN_STATEMENT"(_NodeID integer)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_ReturnValueNodeID         integer;
_ProgramID                 integer;
_FunctionDeclarationNodeID integer;
_RetNodeID                 integer;
_ProgramNodeID             integer;
_OK                        boolean;
BEGIN

SELECT
    Edges.ParentNodeID
INTO
    _ReturnValueNodeID
FROM Edges
INNER JOIN Nodes ON Nodes.NodeID = Edges.ChildNodeID
WHERE Nodes.NodeID = _NodeID
AND Edges.DeathPhaseID IS NULL
AND Nodes.DeathPhaseID IS NULL;
IF _ReturnValueNodeID IS NULL THEN
    _ReturnValueNodeID := _NodeID;
END IF;

PERFORM Log(
    _NodeID   := _NodeID,
    _Severity := 'DEBUG3',
    _Message  := format('Return statement %s', Colorize(Node(_NodeID),'CYAN'))
);

SELECT ProgramID INTO STRICT _ProgramID FROM Nodes WHERE NodeID = _NodeID;

_FunctionDeclarationNodeID := Find_Node(
    _NodeID  := _NodeID,
    _Descend := TRUE,
    _Strict  := FALSE,
    _Path    := '-> FUNCTION_DECLARATION'
);
IF _FunctionDeclarationNodeID IS NOT NULL THEN
    _RetNodeID := Find_Node(
        _NodeID  := _FunctionDeclarationNodeID,
        _Descend := FALSE,
        _Strict  := TRUE,
        _Path    := '<- RET'
    );
    PERFORM "EVAL"."ENTER_RET"(
        _NodeID            := _RetNodeID,
        _ReturnValueNodeID := _ReturnValueNodeID
    );
ELSE
    IF NOT (Language(_NodeID)).ReturnFromTopLevel THEN
        PERFORM Error(
            _NodeID := _NodeID,
            _ErrorType := 'CANNOT_RETURN_FROM_TOP_LEVEL'
        );
        RETURN;
    END IF;

    -- Returning from program
    _ProgramNodeID := Get_Program_Node(_ProgramID := _ProgramID);
    _RetNodeID := Find_Node(
        _NodeID  := _ProgramNodeID,
        _Descend := FALSE,
        _Strict  := TRUE,
        _Path    := '<- RET'
    );
    PERFORM Set_Program_Node(_ProgramNodeID, 'LEAVE');
    PERFORM Set_Reference_Node(
        _ReferenceNodeID := _ReturnValueNodeID,
        _NodeID          := _ProgramNodeID
    );
END IF;

RETURN;
END;
$$;
