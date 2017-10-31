CREATE OR REPLACE FUNCTION "EVAL"."LEAVE_CALL"(_NodeID integer)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID                 integer;
_Walkable                   boolean;
_RetNodeID                 integer;
_RetEdgeID                 integer;
_NextNodeID                integer;
_FunctionDeclarationNodeID integer;
_FunctionInstanceNodeID    integer;
_AllocaNodeID              integer;
_VariableNodeID            integer;
_ReturningCall             boolean;
_NodeType                  text;
_ImplementationFunction    text;
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
    RAISE EXCEPTION 'Unexpected NodeType % NodeID % (%)', _NodeType, _NodeID, Node(_NodeID);
END IF;

SELECT
    RET.NodeID,
    RET.EdgeID,
    Nodes.Walkable IS TRUE
INTO
    _RetNodeID,
    _RetEdgeID,
    _ReturningCall
FROM (
    SELECT
        EdgeID,
        ChildNodeID AS NodeID
    FROM Edges
    WHERE ParentNodeID  = _NodeID
    AND   DeathPhaseID IS NULL
    ORDER BY EdgeID DESC
    LIMIT 1
) AS RET
INNER JOIN Nodes     ON Nodes.NodeID         = RET.NodeID
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
WHERE Nodes.DeathPhaseID IS NULL
AND   NodeTypes.NodeType = 'RET';
IF NOT FOUND THEN
    _FunctionInstanceNodeID := Clone_Node(_NodeID := _FunctionDeclarationNodeID, _SelfRef := FALSE);

    UPDATE Nodes SET
        Environment = Get_Node_Lexical_Environment(NodeID)
    WHERE NodeID = _FunctionInstanceNodeID
    RETURNING TRUE INTO STRICT _OK;

    _RetNodeID := Find_Node(_NodeID := _FunctionInstanceNodeID, _Descend := FALSE, _Strict := TRUE, _Path := '<- RET');
    PERFORM Set_Walkable(_FunctionInstanceNodeID, TRUE);
    PERFORM New_Edge(
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
    PERFORM Set_Program_Node(_FunctionInstanceNodeID, 'ENTER');
END IF;

RETURN;
END;
$$;
