CREATE OR REPLACE FUNCTION "MAP_VARIABLES"."ENTER_IDENTIFIER"(_NodeID integer) RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID                 integer;
_Name                      text;
_FunctionNameNodeID        integer;
_FunctionDeclarationNodeID integer;
_VariableNodeID            integer;
_ChildNodeID               integer;
_OK                        boolean;
BEGIN

IF Find_Node(_NodeID := _NodeID, _Descend := FALSE, _Strict := FALSE, _Path := '-> VARIABLE') IS NOT NULL
THEN
    RETURN FALSE;
END IF;

SELECT
    Nodes.ProgramID,
    Nodes.PrimitiveValue
INTO STRICT
    _ProgramID,
    _Name
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
    _Paths   := ARRAY['<- LET_STATEMENT|STORE_ARGS <- VARIABLE', _Name]
);
IF _VariableNodeID IS NULL THEN
    _VariableNodeID := Find_Node(
        _NodeID  := Find_Node(
            _NodeID  := _NodeID,
            _Descend := TRUE,
            _Strict  := FALSE,
            _Paths   := ARRAY['-> FUNCTION_DECLARATION -> LET_STATEMENT <- VARIABLE <- IDENTIFIER', _Name]
        ),
        _Descend := FALSE,
        _Strict  := FALSE,
        _Paths   := ARRAY['-> VARIABLE -> LET_STATEMENT <- FUNCTION_DECLARATION']
    );
    IF _VariableNodeID IS NULL THEN
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
