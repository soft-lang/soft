CREATE OR REPLACE FUNCTION "REDUCE"."ENTER_PROGRAM"(_NodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID     integer;
_LanguageID    integer;
_LogSeverity   severity;
_DidWork       boolean;
_NOPNodeID     integer;
_NodeTypeID    integer;
_NodeType      text;
_PrimitiveType regtype;
_ParentNodeID  integer;
_ChildNodeID   integer;
_ProgramNodeID integer;
_OK            boolean;
_Killed        integer;
_NodePattern   text;
BEGIN

SELECT
    Nodes.ProgramID,
    NodeTypes.LanguageID,
    Languages.LogSeverity
INTO STRICT
    _ProgramID,
    _LanguageID,
    _LogSeverity
FROM Nodes
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
INNER JOIN Programs  ON Programs.ProgramID   = Nodes.ProgramID
INNER JOIN Phases    ON Phases.PhaseID       = Programs.PhaseID
INNER JOIN Languages ON Languages.LanguageID = Phases.LanguageID
WHERE Nodes.NodeID     = _NodeID
AND Phases.Phase       = 'REDUCE'
AND NodeTypes.NodeType = 'PROGRAM';

PERFORM Log(
    _NodeID   := _NodeID,
    _Severity := 'DEBUG1',
    _Message  := format('Reducing tree by killing unnecessary valueless middle-men nodes')
);

_Killed := 0;
LOOP
    _DidWork := FALSE;
    FOR      _NOPNodeID,      _NodeTypeID,          _NodeType,          _PrimitiveType,          _NodePattern IN
    SELECT Nodes.NodeID, Nodes.NodeTypeID, NodeTypes.NodeType, NodeTypes.PrimitiveType, NodeTypes.NodePattern
    FROM Nodes
    INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
    WHERE Nodes.ProgramID       = _ProgramID
    AND Nodes.DeathPhaseID      IS NULL
    AND Nodes.PrimitiveType     IS NULL
    AND NodeTypes.PrimitiveType IS NULL
    AND NodeTypes.NodeSeverity  IS NULL
    AND NOT EXISTS (
        SELECT 1 FROM pg_proc
        INNER JOIN pg_namespace ON pg_namespace.oid  = pg_proc.pronamespace
        INNER JOIN Phases       ON Phases.Phase      = pg_namespace.nspname
                               AND Phases.LanguageID = _LanguageID
        WHERE pg_proc.proname IN (NodeTypes.NodeType, 'ENTER_'||NodeTypes.NodeType, 'LEAVE_'||NodeTypes.NodeType)
    )
    AND (SELECT COUNT(*) FROM Edges WHERE Edges.DeathPhaseID IS NULL AND Edges.ParentNodeID = Nodes.NodeID)  = 1
    AND (SELECT COUNT(*) FROM Edges WHERE Edges.DeathPhaseID IS NULL AND Edges.ChildNodeID  = Nodes.NodeID) <= 1
    LOOP
        SELECT ChildNodeID                                INTO STRICT _ChildNodeID  FROM Edges WHERE DeathPhaseID IS NULL AND ParentNodeID = _NOPNodeID;
        SELECT ParentNodeID                               INTO        _ParentNodeID FROM Edges WHERE DeathPhaseID IS NULL AND ChildNodeID  = _NOPNodeID;
        IF FOUND THEN
            SELECT Kill_Edge(EdgeID)                      INTO STRICT _OK           FROM Edges WHERE DeathPhaseID IS NULL AND ChildNodeID  = _NOPNodeID AND ParentNodeID = _ParentNodeID;
            SELECT Set_Edge_Parent(EdgeID, _ParentNodeID) INTO STRICT _OK           FROM Edges WHERE DeathPhaseID IS NULL AND ParentNodeID = _NOPNodeID AND ChildNodeID  = _ChildNodeID;
        ELSE
            SELECT Kill_Edge(EdgeID)                      INTO STRICT _OK           FROM Edges WHERE DeathPhaseID IS NULL AND ParentNodeID = _NOPNodeID AND ChildNodeID  = _ChildNodeID;
        END IF;
        SELECT Kill_Node(NodeID)                          INTO STRICT _OK           FROM Nodes WHERE DeathPhaseID IS NULL AND NodeID       = _NOPNodeID;
        _Killed := _Killed + 1;
        PERFORM Log(
            _NodeID   := _NodeID,
            _Severity := 'DEBUG2',
            _Message  := format('%s -> %s -> %s',
                Colorize(Node(_ParentNodeID),'GREEN'),
                Colorize(Node(_NOPNodeID),'RED'),
                Colorize(Node(_ChildNodeID),'GREEN')
            )
        );
        IF _PrimitiveType IS NOT NULL THEN
            UPDATE Nodes
            SET NodeTypeID = _NodeTypeID
            WHERE NodeID = _ParentNodeID
            AND DeathPhaseID IS NULL
            RETURNING TRUE INTO STRICT _OK;
        END IF;
        _DidWork := TRUE;
    END LOOP;
    IF _DidWork THEN
        CONTINUE;
    END IF;
    EXIT;
END LOOP;

PERFORM Log(
    _NodeID   := _NodeID,
    _Severity := 'INFO',
    _Message  := format('OK, killed %s useless nodes', _Killed)
);

RETURN TRUE;
END;
$$;
