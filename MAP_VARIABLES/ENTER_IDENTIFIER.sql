CREATE OR REPLACE FUNCTION "MAP_VARIABLES"."ENTER_IDENTIFIER"(_NodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID                 integer;
_LanguageID                integer;
_Name                      text;
_FunctionNameNodeID        integer;
_FunctionDeclarationNodeID integer;
_VariableNodeID            integer;
_ChildNodeID               integer;
_ImplementationFunction    text;
_OK                        boolean;
BEGIN

IF Find_Node(_NodeID := _NodeID, _Descend := FALSE, _Strict := FALSE, _Path := '-> VARIABLE') IS NOT NULL
THEN
    RETURN FALSE;
END IF;

SELECT
    Nodes.ProgramID,
    Nodes.PrimitiveValue,
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

_VariableNodeID := Find_Node(
    _NodeID  := _NodeID,
    _Descend := TRUE,
    _Strict  := FALSE,
    _Paths   := ARRAY[
        '<- LET_STATEMENT 1<- VARIABLE[1]',
        '<- STORE_ARGS     <- VARIABLE[1]'
    ],
    _Names   := ARRAY[_Name]
);
IF _VariableNodeID IS NULL THEN
    _VariableNodeID := Find_Node(
        _NodeID  := Find_Node(
            _NodeID  := _NodeID,
            _Descend := TRUE,
            _Strict  := FALSE,
            _Paths   := ARRAY['-> FUNCTION_DECLARATION -> LET_STATEMENT <- VARIABLE <- IDENTIFIER[1]'],
            _Names   := ARRAY[_Name]
        ),
        _Descend := FALSE,
        _Strict  := FALSE,
        _Paths   := ARRAY['-> VARIABLE -> LET_STATEMENT <- FUNCTION_DECLARATION']
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
        PERFORM Log(
            _NodeID   := _NodeID,
            _Severity := 'ERROR',
            _Message  := format('Undefined variable %s', Colorize(_Name, 'RED'))
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
