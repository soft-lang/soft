CREATE OR REPLACE FUNCTION "EVAL"."LEAVE_CALL"(_NodeID integer) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID                 integer;
_Walkable                  boolean;
_RetNodeID                 integer;
_NextNodeID                integer;
_FunctionDeclarationNodeID integer;
_FunctionInstanceNodeID    integer;
_AllocaNodeID              integer;
_VariableNodeID            integer;
_ReturningCall             boolean;
_NodeType                  text;
_ImplementationFunction    text;
_ContinuationEdgeID        integer;
_OK                        boolean;
BEGIN

SELECT ProgramID INTO STRICT _ProgramID FROM Nodes WHERE NodeID = _NodeID;

SELECT                  X.ParentNodeID, NodeTypes.NodeType
INTO STRICT _FunctionDeclarationNodeID,          _NodeType
FROM (
    SELECT ParentNodeID
    FROM Edges
    WHERE ChildNodeID  = _NodeID
    AND   DeathPhaseID IS NULL
    ORDER BY EdgeID
    LIMIT 1
) AS X
INNER JOIN Nodes     ON Nodes.NodeID         = X.ParentNodeID
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
WHERE Nodes.DeathPhaseID IS NULL;

IF _NodeType = 'FUNCTION_DECLARATION' THEN
    -- Normal function
ELSIF _NodeType = 'IDENTIFIER' THEN
    -- Built-in function
    SELECT BuiltInFunctions.ImplementationFunction
    INTO                   _ImplementationFunction
    FROM BuiltInFunctions
    INNER JOIN Nodes     ON Nodes.PrimitiveValue = BuiltInFunctions.Identifier
    INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
    WHERE Nodes.NodeID         = _FunctionDeclarationNodeID
    AND   NodeTypes.LanguageID = BuiltInFunctions.LanguageID;

    PERFORM Log(
        _NodeID   := _NodeID,
        _Severity := 'DEBUG3',
        _Message  := format('Execute built-in function %I', Colorize(_ImplementationFunction, 'CYAN'))
    );

    EXECUTE format('SELECT %I.%I(_NodeID := %s::integer)', 'BUILT_IN_FUNCTIONS', _ImplementationFunction, _NodeID);

    RETURN;
ELSE
    RAISE EXCEPTION 'Unexpected NodeType %', _NodeType;
END IF;

SELECT
    Edges.ChildNodeID,
    Nodes.Walkable IS NOT NULL
INTO
    _RetNodeID,
    _ReturningCall
FROM Edges
INNER JOIN Nodes     ON Nodes.NodeID         = Edges.ChildNodeID
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
WHERE Edges.ParentNodeID = _NodeID
AND   NodeTypes.NodeType = 'RET'
AND   Edges.DeathPhaseID IS NULL
AND   Nodes.DeathPhaseID IS NULL;
IF NOT FOUND THEN
    SELECT E2.EdgeID
    INTO _ContinuationEdgeID
    FROM Edges AS E1
    INNER JOIN Nodes       ON Nodes.NodeID         = E1.ParentNodeID
    INNER JOIN NodeTypes   ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
    INNER JOIN Edges AS E2 ON E2.ChildNodeID       = E1.ParentNodeID
    WHERE E1.ChildNodeID     = _FunctionDeclarationNodeID
    AND   NodeTypes.NodeType = 'RET';
    RAISE NOTICE '_ExcludeEdgeIDs %', _ContinuationEdgeID;
    _FunctionInstanceNodeID := Clone_Node(_NodeID := _FunctionDeclarationNodeID, _SelfRef := TRUE, _ExcludeEdgeIDs := ARRAY[_ContinuationEdgeID]);
    _RetNodeID := Find_Node(_NodeID := _FunctionInstanceNodeID, _Descend := FALSE, _Strict := TRUE, _Path := '<- RET');
--    PERFORM Set_Walkable(_FunctionInstanceNodeID, TRUE);
    PERFORM New_Edge(
        _ProgramID    := _ProgramID,
        _ParentNodeID := _NodeID,
        _ChildNodeID  := _RetNodeID
    );
END IF;

IF _ReturningCall THEN
    PERFORM Log(
        _NodeID   := _NodeID,
        _Severity := 'DEBUG3',
        _Message  := format('Returning function call at %s from %s', Colorize(Node(_NodeID),'CYAN'), Colorize(Node(_RetNodeID),'MAGENTA'))
    );
    PERFORM Set_Walkable(_RetNodeID, FALSE);
ELSE
    _FunctionInstanceNodeID := Find_Node(_NodeID := _RetNodeID, _Descend := FALSE, _Strict := TRUE, _Path := '-> FUNCTION_DECLARATION');
    PERFORM Log(
        _NodeID   := _NodeID,
        _Severity := 'DEBUG3',
        _Message  := format('Outgoing function call at %s to %s', Colorize(Node(_NodeID),'CYAN'), Colorize(Node(_FunctionInstanceNodeID),'MAGENTA'))
    );
    PERFORM Set_Walkable(_RetNodeID, TRUE);
    UPDATE Programs SET NodeID = _FunctionInstanceNodeID, Direction = 'ENTER' WHERE ProgramID = _ProgramID AND NodeID = _NodeID RETURNING TRUE INTO STRICT _OK;
END IF;

RETURN;
END;
$$;
