CREATE OR REPLACE FUNCTION Next_Node(_ProgramID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_NodeID          integer;
_PhaseID         integer;
_LanguageID      integer;
_Direction       direction;
_NextPhaseID     integer;
_NextNodeID      integer;
_ChildNodeID     integer;
_EdgeID          integer;
_Count           bigint;
_RunUntilPhaseID integer;
_OK              boolean;
BEGIN

SELECT       Programs.NodeID, Programs.PhaseID, Phases.LanguageID, Programs.Direction, Programs.RunUntilPhaseID
INTO STRICT          _NodeID,         _PhaseID,       _LanguageID,         _Direction,         _RunUntilPhaseID
FROM Programs
INNER JOIN Phases ON Phases.PhaseID = Programs.PhaseID
INNER JOIN Nodes  ON Nodes.NodeID   = Programs.NodeID
WHERE Programs.ProgramID = _ProgramID
FOR UPDATE OF Programs;

IF _Direction IS DISTINCT FROM 'LEAVE' THEN
    RAISE EXCEPTION 'Unexpected Direction %', _Direction;
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
WHERE Edges.ParentNodeID     = _NodeID
AND   ChildNode.DeathPhaseID IS NULL
AND   ChildNode.Walkable     IS TRUE;

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
            _Message  := format('Walking from %s to next node %s', Colorize(Node(_NodeID, _Short := TRUE), 'CYAN'), Colorize(Node(_NextNodeID, _Short := TRUE), 'MAGENTA'))
        );
        UPDATE Programs SET Direction = 'ENTER' WHERE ProgramID = _ProgramID RETURNING Direction INTO STRICT _Direction;
        PERFORM Enter_Node(_NextNodeID);
        RETURN TRUE;
    ELSE
        PERFORM Log(
            _NodeID   := _NodeID,
            _Severity := 'DEBUG5',
            _Message  := format('Descending from %s to its child %s', Colorize(Node(_NodeID, _Short := TRUE), 'CYAN'), Colorize(Node(_ChildNodeID, _Short := TRUE), 'MAGENTA'))
        );
        PERFORM Set_Program_Node(_ChildNodeID);
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
        IF _NextPhaseID > _RunUntilPhaseID THEN
            RETURN FALSE;
        END IF;
        UPDATE Programs SET PhaseID = _NextPhaseID, Direction = 'ENTER' WHERE ProgramID = _ProgramID AND PhaseID = _PhaseID RETURNING TRUE INTO STRICT _OK;
        PERFORM Log(
            _NodeID   := _NodeID,
            _Severity := 'DEBUG3',
            _Message  := format('Phase %s completed, moving on to phase %s', Colorize(Phase(_PhaseID), 'CYAN'), Colorize(Phase(_NextPhaseID), 'MAGENTA')),
            _SaveDOTIR  := TRUE
        );
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

UPDATE Programs SET DeathTime = clock_timestamp() WHERE ProgramID = _ProgramID RETURNING TRUE INTO STRICT _OK;

RETURN FALSE;
END;
$$;
