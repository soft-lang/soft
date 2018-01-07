CREATE OR REPLACE FUNCTION "MAP_VARIABLES"."ENTER_IDENTIFIER"(_NodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID                 integer;
_LanguageID                integer;
_Name                      name;
_FunctionNameNodeID        integer;
_FunctionDeclarationNodeID integer;
_VariableNodeID            integer;
_ChildNodeID               integer;
_ImplementationFunction    text;
_MustBeDeclaredAfter       boolean;
_DeclarationNodeID         integer;
_OK                        boolean;
BEGIN

SELECT
    Nodes.ProgramID,
    Nodes.PrimitiveValue::name,
    Languages.LanguageID
INTO STRICT
    _ProgramID,
    _Name,
    _LanguageID
FROM Nodes
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
INNER JOIN Programs  ON Programs.ProgramID   = Nodes.ProgramID
INNER JOIN Phases    ON Phases.PhaseID       = Programs.PhaseID
INNER JOIN Languages ON Languages.LanguageID = Phases.LanguageID
WHERE Nodes.NodeID      = _NodeID
AND Phases.Phase        = 'MAP_VARIABLES'
AND NodeTypes.NodeType  = 'IDENTIFIER'
AND Nodes.PrimitiveType = 'name'::regtype
AND Nodes.DeathPhaseID  IS NULL;

IF Find_Node(
    _NodeID  := _NodeID,
    _Descend := FALSE,
    _Strict  := FALSE,
    _Path    := '-> GET'
) IS NOT NULL
AND Has_Child(_NodeID, _IsNthParent := 2)
OR Find_Node(
    _NodeID  := _NodeID,
    _Descend := FALSE,
    _Strict  := FALSE,
    _Path    := '-> CALL -> GET'
) IS NOT NULL
AND Has_Child(Child(_NodeID,'CALL'), _IsNthParent := 2)
THEN
    PERFORM Log(
        _NodeID   := _NodeID,
        _Severity := 'DEBUG5',
        _Message  := format('Skipping class field %s, will be resolved during run-time', Colorize(_Name, 'GREEN'))
    );
    PERFORM Set_Walkable(_NodeID, FALSE);
    RETURN TRUE;
END IF;

_VariableNodeID := Resolve(_NodeID, _Name);

_DeclarationNodeID := Find_Node(
    _NodeID  := _NodeID,
    _Descend := TRUE,
    _Strict  := FALSE,
    _Path    := '-> DECLARATION'
);
IF _DeclarationNodeID IS NOT NULL THEN
    IF  Node_Name(NthParent(_DeclarationNodeID, _Nth := 1, _AssertNodeType := 'VARIABLE')) = _Name
    AND Node_Type(NthParent(_DeclarationNodeID, _Nth := 2)) NOT IN ('FUNCTION_DECLARATION', 'CLASS_DECLARATION')
    AND NOT Global(_DeclarationNodeID)
    THEN
        PERFORM Error(
            _NodeID    := _NodeID,
            _ErrorType := 'LOCAL_VAR_IN_OWN_INITIALIZER'
        );
    END IF;
END IF;

IF _VariableNodeID IS NULL THEN
    -- Check if it's a self-referring function:
    _VariableNodeID := Find_Node(
        _NodeID  := Find_Node(
            _NodeID            := _NodeID,
            _Descend           := TRUE,
            _Strict            := FALSE,
            _Names             := ARRAY[_Name],
            _Paths             := ARRAY[
                '-> FUNCTION_DECLARATION -> DECLARATION <- VARIABLE[1]',
                '-> FUNCTION_DECLARATION -> CLASS_DECLARATION -> DECLARATION <- VARIABLE[1]'
            ]
        ),
        _Descend := FALSE,
        _Strict  := FALSE,
        _Paths   := ARRAY[
            '-> DECLARATION <- FUNCTION_DECLARATION',
            '-> DECLARATION <- CLASS_DECLARATION'
        ]
    );
    IF _VariableNodeID IS NULL THEN
        SELECT ImplementationFunction
        INTO  _ImplementationFunction
        FROM BuiltInFunctions
        WHERE LanguageID = _LanguageID
        AND   Identifier = _Name;
        IF FOUND THEN
            PERFORM Log(
                _NodeID   := _NodeID,
                _Severity := 'DEBUG5',
                _Message  := format('Built-in function %L mapped to %L', Colorize(_Name, 'MAGENTA'), Colorize(_ImplementationFunction, 'CYAN'))
            );
            RETURN TRUE;
        END IF;

        PERFORM Error(
            _NodeID    := _NodeID,
            _ErrorType := CASE WHEN Global(_NodeID) THEN 'UNDEFINED_GLOBAL_VARIABLE' ELSE 'UNDEFINED_VARIABLE' END,
            _ErrorInfo := hstore(ARRAY[
                ['IdentifierName', _Name]
            ])
        );
        RETURN FALSE;
    END IF;
END IF;

UPDATE Programs SET Direction = 'LEAVE' WHERE ProgramID = _ProgramID RETURNING TRUE INTO STRICT _OK;
PERFORM Next_Node(_ProgramID);

SELECT Set_Edge_Parent(EdgeID, _ParentNodeID := _VariableNodeID), ChildNodeID INTO STRICT _OK, _ChildNodeID FROM Edges WHERE DeathPhaseID IS NULL AND ParentNodeID = _NodeID;
PERFORM Kill_Node(_NodeID);

RETURN TRUE;
END;
$$;
