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
_SaveDOT      boolean;
_OK           boolean;
BEGIN

IF EXISTS (
    SELECT 1 FROM Log
    INNER JOIN Phases ON Phases.PhaseID = Log.PhaseID
    WHERE Log.ProgramID  = _ProgramID
    AND   Log.Severity  >= Phases.StopSeverity
) THEN
    RETURN FALSE;
END IF;

IF (SELECT NodeID FROM Programs WHERE ProgramID = _ProgramID) IS NULL THEN
    PERFORM Log(
        _NodeID   := _NodeID,
        _Severity := 'DEBUG4',
        _Message  := format('No program node, exiting')
    );
    RETURN FALSE;
END IF;

SELECT       Programs.NodeID, Programs.PhaseID, Phases.LanguageID, Programs.Direction, Phases.SaveDOT
INTO STRICT          _NodeID,         _PhaseID,       _LanguageID,         _Direction,       _SaveDOT
FROM Programs
INNER JOIN Phases ON Phases.PhaseID = Programs.PhaseID
INNER JOIN Nodes  ON Nodes.NodeID   = Programs.NodeID
WHERE Programs.ProgramID = _ProgramID
FOR UPDATE OF Programs;

PERFORM Log(
    _NodeID   := _NodeID,
    _Severity := 'DEBUG4',
    _Message  := format('%s %s', _Direction, Colorize(Node(_NodeID, _Short := TRUE))),
    _SaveDOT  := _SaveDOT
);

IF NOT EXISTS (
    SELECT 1
    FROM Edges
    INNER JOIN Nodes ON Nodes.NodeID = Dereference(Edges.ParentNodeID)
    WHERE Edges.ChildNodeID = _NodeID
    AND Edges.DeathPhaseID  IS NULL
    AND Nodes.DeathPhaseID  IS NULL
    AND Nodes.PrimitiveType IS NULL
) THEN
    PERFORM Eval_Node(_NodeID);
END IF;

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
                _Message  := format('NodeID %s died when entering it', _ParentNodeID)
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

PERFORM Leave_Node(_NodeID);

IF NOT EXISTS (SELECT 1 FROM Nodes WHERE NodeID = _NodeID AND DeathPhaseID IS NULL) THEN
    PERFORM Log(
        _NodeID   := _NodeID,
        _Severity := 'DEBUG3',
        _Message  := format('NodeID %s died when leaving it', _NodeID)
    );
    RETURN TRUE;
ELSIF _NodeID <> (SELECT NodeID FROM Programs WHERE ProgramID = _ProgramID) THEN
    PERFORM Log(
        _NodeID   := _NodeID,
        _Severity := 'DEBUG3',
        _Message  := format('Current program node moved by function', _NodeID)
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
