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
_ProgramID  integer;
_Program    text;
_PhaseID    integer;
_Phase      text;
_Context    text;
_LogID      integer;
_Color      text;
BEGIN
SELECT
    Nodes.ProgramID,
    Programs.Program,
    Phases.PhaseID,
    Phases.Phase
INTO STRICT
    _ProgramID,
    _Program,
    _PhaseID,
    _Phase
FROM Nodes
INNER JOIN Programs ON Programs.ProgramID = Nodes.ProgramID
INNER JOIN Phases   ON Phases.PhaseID     = Programs.PhaseID
WHERE Nodes.NodeID = _NodeID;

_Color := CASE
    WHEN _Severity <= 'DEBUG1' THEN 'BLUE'
    WHEN _Severity < 'WARNING' THEN 'GREEN'
    WHEN _Severity = 'WARNING' THEN 'YELLOW'
    WHEN _Severity > 'WARNING' THEN 'RED'
END;

_Context := '';
IF _SourceCodeCharacters IS NOT NULL THEN
    _Context := E'\n' || Highlight_Code(
        _Text                 := (SELECT TerminalValue FROM Nodes WHERE ProgramID = _ProgramID ORDER BY NodeID LIMIT 1),
        _SourceCodeCharacters := _SourceCodeCharacters,
        _Color                := _Color
    );
END IF;

RAISE NOTICE E'NodeID % program "%" phase "%" %: "%"%', _NodeID, _Program, _Phase, Colorize(_Severity::text, _Color), _Message, _Context;

INSERT INTO Log (NodeID, PhaseID,  Severity,  Message,  SourceCodeCharacters,  NodeIDs)
SELECT          _NodeID, PhaseID, _Severity, _Message, _SourceCodeCharacters, _NodeIDs
FROM Programs WHERE ProgramID = _ProgramID
RETURNING LogID INTO STRICT _LogID;
RETURN _LogID;
END;
$$;
