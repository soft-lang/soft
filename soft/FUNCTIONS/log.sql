CREATE OR REPLACE FUNCTION Log(
_NodeID   integer,
_Severity severity,
_Message  text,
_SaveDOT  boolean DEFAULT FALSE
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
_DOTID       integer;
BEGIN
SELECT
    Nodes.ProgramID,
    Programs.Program,
    Phases.PhaseID,
    Phases.Phase,
    Programs.LogSeverity
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

IF _SaveDOT THEN
    _DOTID := Save_DOT(_NodeID := _NodeID);
END IF;

INSERT INTO Log (ProgramID,  NodeID, PhaseID,  Severity,  Message,  DOTID)
SELECT           ProgramID, _NodeID, PhaseID, _Severity, _Message, _DOTID
FROM Programs WHERE ProgramID = _ProgramID
RETURNING LogID INTO STRICT _LogID;
RETURN _LogID;
END;
$$;
