CREATE OR REPLACE FUNCTION "PARSE_ERRORS"."ENTER_PROGRAM"(_NodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID                 integer;
_LanguageID                integer;
_ErrorNodeID               integer;
_Nodes                     text;
_ErrorType                 text;
_ExpandedNodePattern       text;
_ErrorAtNodeID             integer;
_FirstNodePattern CONSTANT text := '^<A-Z_]+(\d+)>';
BEGIN

SELECT
    Nodes.ProgramID,
    NodeTypes.LanguageID
INTO STRICT
    _ProgramID,
    _LanguageID
FROM Nodes
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
INNER JOIN Programs  ON Programs.ProgramID   = Nodes.ProgramID
INNER JOIN Phases    ON Phases.PhaseID       = Programs.PhaseID
INNER JOIN Languages ON Languages.LanguageID = Phases.LanguageID
WHERE Nodes.NodeID     = _NodeID
AND Phases.Phase       = 'PARSE_ERRORS'
AND NodeTypes.NodeType = 'PROGRAM'
AND Nodes.DeathPhaseID IS NULL;

RAISE NOTICE 'PARSE_ERRORS NodeID % ProgramID % LanguageID %', _NodeID, _ProgramID, _LanguageID;

WITH RECURSIVE
Parents AS (
    SELECT Log.NodeID AS ParentNodeID
    FROM Log
    INNER JOIN Phases ON Phases.PhaseID = Log.PhaseID
    WHERE Log.ProgramID = _ProgramID
    AND   Phases.Phase  = 'PARSE'
    AND   Log.Severity >= 'WARNING'
    UNION ALL
    SELECT Edges.ParentNodeID
    FROM Edges
    INNER JOIN Parents ON Parents.ParentNodeID = Edges.ChildNodeID
)
SELECT string_agg(format('<%s%s>',NodeTypes.NodeType,Nodes.NodeID), '' ORDER BY Nodes.NodeID)
INTO _Nodes
FROM Parents
INNER JOIN Nodes     ON Nodes.NodeID         = Parents.ParentNodeID
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
INNER JOIN Phases    ON Phases.PhaseID       = Nodes.BirthPhaseID
WHERE Phases.Phase = 'TOKENIZE';

UPDATE ErrorTypes
SET ExpandedNodePattern = ('^'||Expand_Node_Pattern(NodePattern, LanguageID))
WHERE LanguageID        = _LanguageID
AND NodePattern         IS NOT NULL
AND ExpandedNodePattern IS NULL;

IF _Nodes IS NULL THEN
    -- No parsing errors
    RETURN TRUE;
END IF;

PERFORM Log(
    _NodeID    := _NodeID,
    _Severity  := 'DEBUG1',
    _Message   := format('Parsing error nodes %s', Colorize(_Nodes, 'MAGENTA'))
);

LOOP
    PERFORM Log(
        _NodeID   := _NodeID,
        _Severity := 'DEBUG5',
        _Message  := format('Parsing %s', _Nodes)
    );

    SELECT
        ErrorType,
        ExpandedNodePattern
    INTO
        _ErrorType,
        _ExpandedNodePattern
    FROM ErrorTypes
    WHERE LanguageID = _LanguageID
    AND NodePattern IS NOT NULL
    AND _Nodes ~ ExpandedNodePattern
    ORDER BY ErrorTypeID
    LIMIT 1;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'No matching ErrorType NodeID %: %', _NodeID, _Nodes;
    END IF;

    _ErrorAtNodeID := Get_Capturing_Group(_String := _Nodes, _Pattern := _FirstNodePattern, _Strict := TRUE)::integer;

    PERFORM Error(
        _NodeID    := _ErrorAtNodeID,
        _ErrorType := _ErrorType
    );

    _Nodes := regexp_replace(_Nodes, _ExpandedNodePattern, '');

    IF _Nodes = '' THEN
        EXIT;
    END IF;
END LOOP;

RETURN TRUE;
END;
$$;
