CREATE OR REPLACE FUNCTION Log(
_NodeID   integer,
_Severity severity,
_Message  text
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID   integer;
_Program     text;
_PhaseID     integer;
_Phase       text;
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

PERFORM Notice(format('%s %s: "%s"', _Phase, Colorize(_Severity::text, _Color), _Message));

INSERT INTO Log (ProgramID,  NodeID, PhaseID,  Severity,  Message)
SELECT           ProgramID, _NodeID, PhaseID, _Severity, _Message
FROM Programs WHERE ProgramID = _ProgramID
RETURNING LogID INTO STRICT _LogID;
RETURN _LogID;
END;
$$;
