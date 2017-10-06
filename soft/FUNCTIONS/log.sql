CREATE OR REPLACE FUNCTION Log(
_NodeID               integer,
_Severity             severity,
_Message              text,
_SourceCodeCharacters integer[] DEFAULT NULL,
_NodeIDs              integer[] DEFAULT NULL
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID   integer;
_Program     text;
_PhaseID     integer;
_Phase       text;
_Context     text;
_LogID       integer;
_Color       text;
_LogSeverity severity;
BEGIN
SELECT
    Nodes.ProgramID,
    Programs.Program,
    Phases.PhaseID,
    Phases.Phase,
    Languages.LogSeverity
INTO STRICT
    _ProgramID,
    _Program,
    _PhaseID,
    _Phase,
    _LogSeverity
FROM Nodes
INNER JOIN Programs  ON Programs.ProgramID   = Nodes.ProgramID
INNER JOIN Phases    ON Phases.PhaseID       = Programs.PhaseID
INNER JOIN Languages ON Languages.LanguageID = Phases.LanguageID
WHERE Nodes.NodeID = _NodeID;

IF _Severity < _LogSeverity THEN
    RETURN NULL;
END IF;

_Color := CASE
    WHEN _Severity <= 'DEBUG1' THEN 'BLUE'
    WHEN _Severity < 'WARNING' THEN 'GREEN'
    WHEN _Severity = 'WARNING' THEN 'YELLOW'
    WHEN _Severity > 'WARNING' THEN 'RED'
END;

_Context := '';
IF _SourceCodeCharacters IS NOT NULL THEN
    _Context := E'\n' || Highlight_Code(
        _Text                 := Get_Source_Code(_ProgramID),
        _SourceCodeCharacters := _SourceCodeCharacters,
        _Color                := _Color
    );
END IF;

RAISE NOTICE E'% %: "%"%', _Phase, Colorize(_Severity::text, _Color), _Message, _Context;

INSERT INTO Log (ProgramID,  NodeID, PhaseID,  Severity,  Message,  SourceCodeCharacters,  NodeIDs)
SELECT           ProgramID, _NodeID, PhaseID, _Severity, _Message, _SourceCodeCharacters, _NodeIDs
FROM Programs WHERE ProgramID = _ProgramID
RETURNING LogID INTO STRICT _LogID;
RETURN _LogID;
END;
$$;
