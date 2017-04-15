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
_Visited      integer;
_OK           boolean;
BEGIN

SELECT       Programs.NodeID, Programs.PhaseID, Phases.LanguageID, Nodes.Visited
INTO STRICT          _NodeID,         _PhaseID,       _LanguageID,      _Visited
FROM Programs
INNER JOIN Phases ON Phases.PhaseID = Programs.PhaseID
LEFT JOIN Nodes   ON Nodes.NodeID   = Programs.NodeID
WHERE Programs.ProgramID = _ProgramID
FOR UPDATE OF Programs;

IF _NodeID IS NULL THEN
    UPDATE Programs SET NodeID = Get_Program_Node(_ProgramID) RETURNING NodeID INTO STRICT _NodeID;
    UPDATE Nodes SET Visited = 1 WHERE NodeID = _NodeID RETURNING TRUE INTO STRICT _OK;
    PERFORM Enter_Node(_NodeID);
    _Visited := 1;
    RETURN TRUE;
END IF;

PERFORM Log(
    _NodeID   := _NodeID,
    _Severity := 'DEBUG4',
    _Message  := format('Visiting %s', Colorize(Node(_NodeID)))
);

IF NOT EXISTS (
    SELECT 1
    FROM Edges
    INNER JOIN Nodes ON Nodes.NodeID = Edges.ParentNodeID
    WHERE Edges.ChildNodeID = _NodeID
    AND Edges.DeathPhaseID  IS NULL
    AND Nodes.DeathPhaseID  IS NULL
    AND Nodes.TerminalType  IS NULL
    AND Nodes.Walkable      IS TRUE
) THEN
    PERFORM Eval_Node(_NodeID);
END IF;

SELECT
    Edges.ParentNodeID
INTO
    _ParentNodeID
FROM Edges
INNER JOIN Nodes ON Nodes.NodeID = Edges.ParentNodeID
WHERE Edges.ChildNodeID = _NodeID
AND Nodes.Visited       < _Visited
AND Edges.DeathPhaseID  IS NULL
AND Nodes.DeathPhaseID  IS NULL
AND Nodes.Walkable      IS TRUE
ORDER BY Edges.EdgeID
LIMIT 1;
IF FOUND THEN
    UPDATE Programs SET NodeID = _ParentNodeID WHERE ProgramID = _ProgramID AND NodeID = _NodeID RETURNING TRUE INTO STRICT _OK;
    UPDATE Nodes SET Visited = _Visited WHERE NodeID = _ParentNodeID RETURNING TRUE INTO STRICT _OK;
    PERFORM Enter_Node(_ParentNodeID);
    RETURN TRUE;
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
    Edges.ChildNodeID
INTO
    _EdgeID,
    _ChildNodeID
FROM Edges
INNER JOIN Nodes AS ParentNode ON ParentNode.NodeID    = Edges.ParentNodeID
INNER JOIN Nodes AS ChildNode  ON ChildNode.NodeID     = Edges.ChildNodeID
WHERE Edges.ParentNodeID      = _NodeID
AND   Edges.DeathPhaseID      IS NULL
AND   ParentNode.DeathPhaseID IS NULL
ORDER BY ChildNode.Visited DESC
LIMIT 1;

IF FOUND THEN
    SELECT
        Edges.ParentNodeID
    INTO
        _NextNodeID
    FROM Edges
    INNER JOIN Nodes ON Nodes.NodeID = Edges.ParentNodeID
    WHERE Edges.ChildNodeID = _ChildNodeID
    AND Nodes.Visited       < _Visited
    AND Edges.EdgeID        > _EdgeID
    AND Edges.DeathPhaseID  IS NULL
    AND Nodes.DeathPhaseID  IS NULL
    AND Nodes.Walkable      IS TRUE
    ORDER BY Edges.EdgeID
    LIMIT 1;
    IF FOUND THEN
        PERFORM Log(
            _NodeID   := _NodeID,
            _Severity := 'DEBUG5',
            _Message  := format('Walking from %s to next node %s', Colorize(Node(_NodeID), 'CYAN'), Colorize(Node(_NextNodeID), 'MAGENTA'))
        );
        UPDATE Programs SET NodeID = _NextNodeID WHERE ProgramID = _ProgramID AND NodeID = _NodeID RETURNING TRUE INTO STRICT _OK;
        UPDATE Nodes SET Visited = _Visited WHERE NodeID = _NextNodeID RETURNING TRUE INTO STRICT _OK;
        PERFORM Enter_Node(_NextNodeID);
        RETURN TRUE;
    ELSE
        PERFORM Log(
            _NodeID   := _NodeID,
            _Severity := 'DEBUG5',
            _Message  := format('Descending from %s to its child %s', Colorize(Node(_NodeID), 'CYAN'), Colorize(Node(_ChildNodeID), 'MAGENTA'))
        );
        UPDATE Programs SET NodeID = _ChildNodeID WHERE ProgramID = _ProgramID AND NodeID = _NodeID RETURNING TRUE INTO STRICT _OK;
        UPDATE Nodes SET Visited = _Visited WHERE NodeID = _ChildNodeID RETURNING TRUE INTO STRICT _OK;
        RETURN TRUE;
    END IF;
END IF;

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
    UPDATE Programs SET PhaseID = _NextPhaseID, NodeID = NULL WHERE ProgramID = _ProgramID AND PhaseID = _PhaseID RETURNING TRUE INTO STRICT _OK;
    UPDATE Nodes SET Visited = 0 WHERE ProgramID = _ProgramID;
    RETURN TRUE;
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
