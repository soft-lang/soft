CREATE OR REPLACE FUNCTION "PARSE_ERRORS"."ENTER_PROGRAM"(_NodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID   integer;
_LanguageID  integer;
_ErrorNodeID integer;
_Nodes       text;
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
SELECT string_agg(format('<%s%s>',NodeTypes.NodeType,Nodes.NodeID), ' ' ORDER BY Nodes.NodeID)
INTO _Nodes
FROM Parents
INNER JOIN Nodes     ON Nodes.NodeID         = Parents.ParentNodeID
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
INNER JOIN Phases    ON Phases.PhaseID       = Nodes.BirthPhaseID
WHERE Phases.Phase = 'TOKENIZE';

RAISE NOTICE 'Error Nodes: %', _Nodes;

RETURN TRUE;
END;
$$;
