CREATE OR REPLACE FUNCTION Walk_Tree(_ProgramID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_NodeID       integer;
_PhaseID      integer;
_LanguageID   integer;
_NextPhaseID  integer;
_ParentNodeID integer;
_NextNodeID   integer;
_ChildNodeID  integer;
_EdgeID       integer;
_Count        bigint;
_Direction    direction;
_SaveDOTIR    boolean;
_Phase        text;
_Severity     severity;
_OK           boolean;
BEGIN

SELECT
    Phases.Phase,
    Log.Severity
INTO
    _Phase,
    _Severity
FROM Log
INNER JOIN Phases ON Phases.PhaseID = Log.PhaseID
WHERE Log.ProgramID  = _ProgramID
AND   Log.Severity  >= Phases.StopSeverity
LIMIT 1;
IF FOUND THEN
    PERFORM Notice(Colorize(format('Stopping due to %s during %s', _Severity, _Phase), 'RED'));
    RETURN FALSE;
END IF;

IF (SELECT NodeID FROM Programs WHERE ProgramID = _ProgramID) IS NULL THEN
    RAISE NOTICE 'No program node for ProgramID %, exiting', _ProgramID;
    RETURN FALSE;
END IF;

SELECT       Programs.NodeID, Programs.PhaseID, Phases.LanguageID, Programs.Direction, Phases.SaveDOTIR
INTO STRICT          _NodeID,         _PhaseID,       _LanguageID,         _Direction,       _SaveDOTIR
FROM Programs
INNER JOIN Phases ON Phases.PhaseID = Programs.PhaseID
INNER JOIN Nodes  ON Nodes.NodeID   = Programs.NodeID
WHERE Programs.ProgramID = _ProgramID
FOR UPDATE OF Programs;

PERFORM Log(
    _NodeID    := _NodeID,
    _Severity  := 'DEBUG4',
    _SaveDOTIR := _SaveDOTIR
);

UPDATE Programs
SET Iterations = Iterations + 1
WHERE ProgramID = _ProgramID
RETURNING TRUE INTO STRICT _OK;

IF _Direction = 'ENTER' THEN
    SELECT
        Edges.ParentNodeID
    INTO
        _ParentNodeID
    FROM Edges
    INNER JOIN Nodes ON Nodes.NodeID = Edges.ParentNodeID
    WHERE Edges.ChildNodeID  = _NodeID
    AND Nodes.Walkable      IS TRUE
    AND Edges.DeathPhaseID  IS NULL
    AND Nodes.DeathPhaseID  IS NULL
    ORDER BY Edges.EdgeID
    LIMIT 1;
    IF FOUND THEN
        PERFORM Enter_Node(_ParentNodeID);
        IF NOT EXISTS (SELECT 1 FROM Nodes WHERE NodeID = _ParentNodeID AND DeathPhaseID IS NULL) THEN
            PERFORM Log(
                _NodeID   := _ParentNodeID,
                _Severity := 'DEBUG3',
                _Message  := format('%s died when entering it', Node(_ParentNodeID, _Short := TRUE))
            );
        END IF;
        RETURN TRUE;
    ELSE
        UPDATE Programs SET Direction = 'LEAVE' WHERE ProgramID = _ProgramID RETURNING Direction INTO STRICT _Direction;
    END IF;
END IF;

IF _Direction IS DISTINCT FROM 'LEAVE' THEN
    RAISE EXCEPTION 'Unexpected Direction %', _Direction;
END IF;

PERFORM Eval_Node(_NodeID);

PERFORM Leave_Node(_NodeID);

IF NOT EXISTS (SELECT 1 FROM Nodes WHERE NodeID = _NodeID AND DeathPhaseID IS NULL) THEN
    PERFORM Log(
        _NodeID   := _NodeID,
        _Severity := 'DEBUG3',
        _Message  := format('%s died when leaving it', Node(_NodeID, _Short := TRUE))
    );
    RETURN TRUE;
ELSIF _NodeID <> (SELECT NodeID FROM Programs WHERE ProgramID = _ProgramID) THEN
    PERFORM Log(
        _NodeID   := _NodeID,
        _Severity := 'DEBUG3',
        _Message  := 'Current program node moved by function'
    );
    RETURN TRUE;
END IF;

RETURN Next_Node(_ProgramID);

END;
$$;

CREATE OR REPLACE FUNCTION Walk_Tree(_Language text, _Program text)
RETURNS boolean
LANGUAGE sql
AS $$
SELECT Walk_Tree(Programs.ProgramID)
FROM Programs
INNER JOIN Languages ON Languages.LanguageID = Programs.LanguageID
WHERE Languages.Language = $1
AND   Programs.Program   = $2
$$;
