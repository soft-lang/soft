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

SELECT       Programs.NodeID, Programs.PhaseID, Phases.LanguageID, Programs.Direction
INTO STRICT          _NodeID,         _PhaseID,       _LanguageID,         _Direction
FROM Programs
INNER JOIN Phases ON Phases.PhaseID = Programs.PhaseID
INNER JOIN Nodes  ON Nodes.NodeID   = Programs.NodeID
WHERE Programs.ProgramID = _ProgramID
FOR UPDATE OF Programs;

PERFORM Log(
    _NodeID   := _NodeID,
    _Severity := 'DEBUG4',
    _Message  := format('%s %s', _Direction, Colorize(Node(_NodeID)))
);

IF NOT EXISTS (
    SELECT 1
    FROM Edges
    INNER JOIN Nodes ON Nodes.NodeID = Edges.ParentNodeID
    WHERE Edges.ChildNodeID = _NodeID
    AND Edges.DeathPhaseID  IS NULL
    AND Nodes.DeathPhaseID  IS NULL
    AND Nodes.TerminalType  IS NULL
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

SELECT
    Edges.EdgeID,
    Edges.ChildNodeID,
    COUNT(*) OVER ()
INTO
    _EdgeID,
    _ChildNodeID,
    _Count
FROM Edges
INNER JOIN Nodes AS ParentNode ON ParentNode.NodeID    = Edges.ParentNodeID
INNER JOIN Nodes AS ChildNode  ON ChildNode.NodeID     = Edges.ChildNodeID
WHERE Edges.ParentNodeID = _NodeID
AND   Edges.DeathPhaseID IS NULL;

IF _Count = 1 THEN
    SELECT
        Edges.ParentNodeID
    INTO
        _NextNodeID
    FROM Edges
    INNER JOIN Nodes ON Nodes.NodeID = Edges.ParentNodeID
    WHERE Edges.ChildNodeID =  _ChildNodeID
    AND Edges.EdgeID        >  _EdgeID
    AND Nodes.Walkable      IS TRUE
    AND Edges.DeathPhaseID  IS NULL
    AND Nodes.DeathPhaseID  IS NULL
    ORDER BY Edges.EdgeID
    LIMIT 1;
    IF FOUND THEN
        PERFORM Log(
            _NodeID   := _NodeID,
            _Severity := 'DEBUG5',
            _Message  := format('Walking from %s to next node %s', Colorize(Node(_NodeID), 'CYAN'), Colorize(Node(_NextNodeID), 'MAGENTA'))
        );
        UPDATE Programs SET Direction = 'ENTER' WHERE ProgramID = _ProgramID RETURNING Direction INTO STRICT _Direction;
        PERFORM Enter_Node(_NextNodeID);
        RETURN TRUE;
    ELSE
        PERFORM Log(
            _NodeID   := _NodeID,
            _Severity := 'DEBUG5',
            _Message  := format('Descending from %s to its child %s', Colorize(Node(_NodeID), 'CYAN'), Colorize(Node(_ChildNodeID), 'MAGENTA'))
        );
        UPDATE Programs SET NodeID = _ChildNodeID WHERE ProgramID = _ProgramID AND NodeID = _NodeID RETURNING TRUE INTO STRICT _OK;
        RETURN TRUE;
    END IF;
ELSIF _Count IS NULL THEN
    SELECT    PhaseID
    INTO _NextPhaseID
    FROM Phases
    WHERE LanguageID = _LanguageID
    AND      PhaseID > _PhaseID
    ORDER BY PhaseID
    LIMIT 1;
    IF FOUND THEN
        PERFORM Log(
            _NodeID   := _NodeID,
            _Severity := 'DEBUG3',
            _Message  := format('Phase %s completed, moving on to phase %s', Colorize(Phase(_PhaseID), 'CYAN'), Colorize(Phase(_NextPhaseID), 'MAGENTA'))
        );
        UPDATE Programs SET PhaseID = _NextPhaseID, Direction = 'ENTER' WHERE ProgramID = _ProgramID AND PhaseID = _PhaseID RETURNING TRUE INTO STRICT _OK;
        PERFORM Enter_Node(_NodeID);
        RETURN TRUE;
    END IF;
ELSE
    RAISE EXCEPTION 'Multiple % walkable walkable children found under NodeID %, one of them is NodeID % via EdgeID %', _Count, _NodeID, _ChildNodeID, _EdgeID;
END IF;


PERFORM Log(
    _NodeID   := _NodeID,
    _Severity := 'DEBUG3',
    _Message  := format('Final phase %s completed', Colorize(Phase(_PhaseID)))
);
RETURN FALSE;
END;
$$;

CREATE OR REPLACE FUNCTION Walk_Tree(_Program text)
RETURNS boolean
LANGUAGE sql
AS $$
SELECT Walk_Tree(ProgramID) FROM Programs WHERE Program = $1
$$;
