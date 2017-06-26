CREATE OR REPLACE FUNCTION Next_Node(_ProgramID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_NodeID                integer;
_PhaseID               integer;
_LanguageID            integer;
_Direction             direction;

_NextPhaseID           integer;
_NextNodeID            integer;
_ChildNodeID           integer;
_ChildNodeWalkable     boolean;
_EdgeID                integer;
_CountChildrenWalkable bigint;
_CountChildrenTotal    bigint;
_OK                    boolean;
BEGIN

SELECT       Programs.NodeID, Programs.PhaseID, Phases.LanguageID, Programs.Direction
INTO STRICT          _NodeID,         _PhaseID,       _LanguageID,         _Direction
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
    ChildNode.Walkable,
    COUNT(CASE WHEN ChildNode.Walkable THEN 1 END) OVER (),
    COUNT(*) OVER ()
INTO
    _EdgeID,
    _ChildNodeID,
    _ChildNodeWalkable,
    _CountChildrenWalkable,
    _CountChildrenTotal
FROM Edges
INNER JOIN Nodes AS ParentNode ON ParentNode.NodeID    = Edges.ParentNodeID
INNER JOIN Nodes AS ChildNode  ON ChildNode.NodeID     = Edges.ChildNodeID
WHERE Edges.ParentNodeID = _NodeID
AND   Edges.DeathPhaseID IS NULL
ORDER BY ChildNode.Walkable DESC;

IF _CountChildrenWalkable > 1 THEN
    RAISE EXCEPTION 'Multiple % walkable walkable children found under NodeID %, one of them is NodeID % via EdgeID %', _CountChildrenWalkable, _NodeID, _ChildNodeID, _EdgeID;
ELSIF _CountChildrenWalkable IS DISTINCT FROM 1 AND _CountChildrenTotal > 1 THEN
    RAISE EXCEPTION 'There is not a single walkable children but multiple % non-walkable walkable children found under NodeID %, one of them is NodeID % via EdgeID %', _CountChildrenTotal, _NodeID, _ChildNodeID, _EdgeID;
END IF;

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
ELSIF _ChildNodeWalkable THEN
    PERFORM Log(
        _NodeID   := _NodeID,
        _Severity := 'DEBUG5',
        _Message  := format('Descending from %s to its child %s', Colorize(Node(_NodeID), 'CYAN'), Colorize(Node(_ChildNodeID), 'MAGENTA'))
    );
    UPDATE Programs SET NodeID = _ChildNodeID WHERE ProgramID = _ProgramID AND NodeID = _NodeID RETURNING TRUE INTO STRICT _OK;
    RETURN TRUE;
ELSE
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
END IF;

PERFORM Log(
    _NodeID   := _NodeID,
    _Severity := 'DEBUG3',
    _Message  := format('Final phase %s completed', Colorize(Phase(_PhaseID)))
);

RETURN FALSE;
END;
$$;
