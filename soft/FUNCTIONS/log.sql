CREATE OR REPLACE FUNCTION Log(
_NodeID    integer,
_Severity  severity,
_Message   text    DEFAULT NULL,
_SaveDOTIR boolean DEFAULT FALSE
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
_DOTIRID       integer;
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

IF _SaveDOTIR THEN
    _DOTIRID := Save_DOTIR(_NodeID := _NodeID);
END IF;

IF _Message IS NULL THEN
    RETURN NULL;
END IF;

PERFORM Notice(format('%s %s: "%s"', _Phase, Colorize(_Severity::text, _Color), _Message));

INSERT INTO Log (ProgramID,  NodeID, PhaseID,  Severity,  Message,  DOTIRID)
SELECT           ProgramID, _NodeID, PhaseID, _Severity, _Message, _DOTIRID
FROM Programs WHERE ProgramID = _ProgramID
RETURNING LogID INTO STRICT _LogID;
RETURN _LogID;
END;
$$;
