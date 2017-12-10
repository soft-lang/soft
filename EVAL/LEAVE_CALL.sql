CREATE OR REPLACE FUNCTION "EVAL"."LEAVE_CALL"(_NodeID integer)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID              integer;
_Walkable               boolean;
_RetNodeID              integer;
_RetEdgeID              integer;
_NextNodeID             integer;
_DeclarationNodeID      integer;
_InstanceNodeID         integer;
_FieldNodeID            integer;
_AllocaNodeID           integer;
_VariableNodeID         integer;
_ReturningCall          boolean;
_NodeType               text;
_ImplementationFunction text;
_EnvironmentID          integer;
_Identifier             text;
_LanguageID             integer;
_ParentNodeIDs          integer[];
_InitNodeID             integer;
_Name                   name;
_ClassNodeID            integer;
_ArgumentNodeIDs        integer[];
_OK                     boolean;
BEGIN

SELECT ProgramID INTO STRICT _ProgramID FROM Nodes WHERE NodeID = _NodeID;

SELECT          X.ParentNodeID, NodeTypes.NodeType, Nodes.PrimitiveValue, NodeTypes.LanguageID
INTO STRICT _DeclarationNodeID,          _NodeType,          _Identifier,          _LanguageID
FROM (
    SELECT
        Dereference(ParentNodeID) AS ParentNodeID
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
ELSIF _NodeType = 'CLASS_DECLARATION' THEN
    IF Node_Name(_DeclarationNodeID) IS NOT NULL THEN
        -- Cannot call an instance of a class
        PERFORM Error(
            _NodeID    := _NodeID,
            _ErrorType := 'CAN_ONLY_CALL_FUNCTIONS_AND_CLASSES',
            _ErrorInfo := hstore(ARRAY[
                ['NodeType', _NodeType],
                ['NodeName', Node_Name(_DeclarationNodeID)::text]
            ])
        );
        RETURN;
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
    IF FOUND THEN
        PERFORM Kill_Edge(_RetEdgeID);
        PERFORM Log(
            _NodeID   := _NodeID,
            _Severity := 'DEBUG3',
            _Message  := format('Class initiated, killed edge to init RET, EdgeID %s', _RetEdgeID)
        );
        RETURN;
    END IF; 
    -- Init class
    _Name := Node_Name(Parent(Child(Dereference(_DeclarationNodeID),'DECLARATION'),'VARIABLE'));

    _InstanceNodeID := Clone(_NodeID := _DeclarationNodeID);

    UPDATE Nodes
    SET NodeName = _Name
    WHERE NodeID = _InstanceNodeID
    RETURNING TRUE INTO STRICT _OK;

    _InitNodeID := Get_Field(_InstanceNodeID, (Language(_NodeID)).ClassInitializerName, _Strict := FALSE, _SearchSuperClass := FALSE);
    IF _InitNodeID IS NOT NULL THEN
        _RetNodeID := Find_Node(_NodeID := _InitNodeID, _Descend := FALSE, _Strict := TRUE, _Path := '<- RET');
        PERFORM New_Edge(
            _ParentNodeID := _NodeID,
            _ChildNodeID  := _RetNodeID
        );
        PERFORM Set_Walkable(_RetNodeID, TRUE);
        PERFORM Set_Walkable(_InitNodeID, TRUE);
        PERFORM Set_Program_Node(_InitNodeID, 'ENTER');
        PERFORM Log(
            _NodeID   := _NodeID,
            _Severity := 'DEBUG3',
            _Message  := format('Init call at %s to %s', Colorize(Node(_NodeID),'CYAN'), Colorize(Node(_InitNodeID),'MAGENTA'))
        );
    ELSE
        _ArgumentNodeIDs := Call_Args(_NodeID);
        IF _ArgumentNodeIDs IS NOT NULL THEN
            PERFORM Error(
                _NodeID    := _NodeID,
                _ErrorType := 'WRONG_NUMBER_OF_ARGUMENTS',
                _ErrorInfo := hstore(ARRAY[
                    ['Got', array_length(_ArgumentNodeIDs, 1)::text],
                    ['Want', '0']
                ])
            );
            RETURN;
        END IF;
    END IF;
    PERFORM Set_Reference_Node(_ReferenceNodeID := _InstanceNodeID, _NodeID := _NodeID);
    RETURN;
ELSIF _NodeType = 'IDENTIFIER' THEN

    IF Find_Node(
        _NodeID  := _NodeID,
        _Descend := FALSE,
        _Strict  := FALSE,
        _Path    := '-> GET <- VARIABLE'
    ) IS NOT NULL THEN
        PERFORM Log(
            _NodeID   := _NodeID,
            _Severity := 'DEBUG5',
            _Message  := format('Skipping field %s, will be resolved during run-time', Colorize(_Identifier, 'GREEN'))
        );
        RETURN;
    END IF;

    SELECT ImplementationFunction
    INTO  _ImplementationFunction
    FROM BuiltInFunctions
    WHERE Identifier = _Identifier
    AND   LanguageID = _LanguageID;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'No such built-in function %', _Identifier;
    END IF;

    PERFORM Log(
        _NodeID   := _NodeID,
        _Severity := 'DEBUG3',
        _Message  := format('Execute built-in function %I', Colorize(_ImplementationFunction, 'CYAN'))
    );

    EXECUTE format('SELECT %I.%I(_NodeID := %s::integer)', 'BUILT_IN_FUNCTIONS', _ImplementationFunction, _NodeID);

    RETURN;
ELSE
    PERFORM Error(
        _NodeID    := _NodeID,
        _ErrorType := 'CAN_ONLY_CALL_FUNCTIONS_AND_CLASSES',
        _ErrorInfo := hstore(ARRAY[
            ['NodeType', _NodeType],
            ['NodeName', Node_Name(_DeclarationNodeID)::text]
        ])
    );
    RETURN;
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
    INSERT INTO Environments (ProgramID, EnvironmentID)
    SELECT _ProgramID, MAX(EnvironmentID)+1
    FROM Environments
    WHERE ProgramID = _ProgramID
    RETURNING    EnvironmentID
    INTO STRICT _EnvironmentID;

    PERFORM Log(
        _NodeID   := _NodeID,
        _Severity := 'DEBUG3',
        _Message  := format('Created new EnvironmentID %s to call function', _EnvironmentID)
    );
    IF Child(_DeclarationNodeID, 'CLASS_DECLARATION') IS NOT NULL
    OR Child(_DeclarationNodeID, 'SUPERCLASS')        IS NOT NULL
    OR Closure(_DeclarationNodeID)
    THEN
        _InstanceNodeID := _DeclarationNodeID;
    ELSE
        -- Normal function
        _InstanceNodeID := Clone_Node(_NodeID := _DeclarationNodeID, _SelfRef := FALSE, _EnvironmentID := _EnvironmentID);

        _ClassNodeID := Find_Node(
            _NodeID  := _DeclarationNodeID,
            _Descend := TRUE,
            _Strict  := FALSE,
            _Paths   := ARRAY[
                '-> CLASS_DECLARATION',
                '-> SUPERCLASS'
            ]
        );
        IF _ClassNodeID IS NOT NULL THEN
            PERFORM New_Edge(
                _ParentNodeID := _InstanceNodeID,
                _ChildNodeID  := _ClassNodeID
            );
        END IF;
    END IF;

    _RetNodeID := Find_Node(_NodeID := _InstanceNodeID, _Descend := FALSE, _Strict := TRUE, _Path := '<- RET');
    PERFORM Set_Walkable(_InstanceNodeID, TRUE);
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

    IF Find_Node(_NodeID := _DeclarationNodeID, _Descend := FALSE, _Strict := FALSE, _Path := '-> CLASS_DECLARATION') IS NOT NULL
    OR Closure(_DeclarationNodeID)
    THEN
        -- Class method
        PERFORM Kill_Edge(_RetEdgeID);
        PERFORM Log(
            _NodeID   := _NodeID,
            _Severity := 'DEBUG3',
            _Message  := format('Method returned, killed edge to init RET, EdgeID %s', _RetEdgeID)
        );
    ELSE
        -- Normal function
        PERFORM Set_Walkable(_RetNodeID, FALSE);
    END IF;

ELSE
    _InstanceNodeID := Find_Node(_NodeID := _RetNodeID, _Descend := FALSE, _Strict := TRUE, _Path := '-> FUNCTION_DECLARATION');
    PERFORM Log(
        _NodeID   := _NodeID,
        _Severity := 'DEBUG3',
        _Message  := format('Outgoing function call at %s to %s', Colorize(Node(_NodeID),'CYAN'), Colorize(Node(_InstanceNodeID),'MAGENTA'))
    );
    PERFORM Set_Walkable(_RetNodeID, TRUE);
    PERFORM Set_Program_Node(_InstanceNodeID, 'ENTER');
END IF;

RETURN;
END;
$$;
