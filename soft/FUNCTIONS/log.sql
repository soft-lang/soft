CREATE OR REPLACE FUNCTION Log(
_NodeID    integer,
_Severity  severity,
_Message   text    DEFAULT NULL,
_SaveDOTIR boolean DEFAULT FALSE,
_ErrorType text    DEFAULT NULL,
_ErrorInfo hstore  DEFAULT NULL
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID   integer;
_Program     text;
_PhaseID     integer;
_Phase       text;
_NodeType    text;
_LogID       integer;
_Color       text;
_LogSeverity severity;
_DOTIRID     integer;
BEGIN

SELECT
    Nodes.ProgramID,
    Programs.Program,
    Phases.PhaseID,
    Phases.Phase,
    NodeTypes.NodeType,
    Programs.LogSeverity
INTO STRICT
    _ProgramID,
    _Program,
    _PhaseID,
    _Phase,
    _NodeType,
    _LogSeverity
FROM Nodes
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
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

PERFORM Notice(format('%s %s %s %s %s %s: "%s"', _ProgramID, (SELECT MAX(DOTIRID) FROM DOTIR), _Phase, _NodeType, Colorize(_Severity::text||COALESCE(':'||_ErrorType,''), _Color), _NodeID, _Message));

INSERT INTO Log (ProgramID,  NodeID, PhaseID,  Severity,  Message,  DOTIRID,  ErrorInfo,  ErrorType)
SELECT           ProgramID, _NodeID, PhaseID, _Severity, _Message, _DOTIRID, _ErrorInfo, _ErrorType
FROM Programs WHERE ProgramID = _ProgramID
RETURNING LogID INTO STRICT _LogID;
RETURN _LogID;
END;
$$;
