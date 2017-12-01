CREATE OR REPLACE FUNCTION "REDUCE"."ENTER_PROGRAM"(_NodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID       integer;
_LanguageID      integer;
_DidWork         boolean;
_NOPNodeID       integer;
_NodeTypeID      integer;
_NodeType        text;
_PrimitiveType   regtype;
_ParentNodeID    integer;
_ChildNodeID     integer;
_ProgramNodeID   integer;
_Killed          integer;
_NodePattern     text;
_PrimitiveNodeID integer;
_AbstractNodeID  integer;
_EdgeID          integer;
_PrimitiveValue  text;
_OK              boolean;
BEGIN

PERFORM Log(
    _NodeID   := _NodeID,
    _Severity := 'DEBUG1',
    _Message  := format('Reducing graph by killing unnecessary valueless middle-men nodes')
);

SELECT
    Nodes.ProgramID,
    NodeTypes.LanguageID
INTO STRICT
    _ProgramID,
    _LanguageID
FROM Nodes
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
INNER JOIN Programs  ON Programs.ProgramID   = Nodes.ProgramID
INNER JOIN Phases    ON Phases.PhaseID       = Programs.PhaseID
INNER JOIN Languages ON Languages.LanguageID = Phases.LanguageID
WHERE Nodes.NodeID     = _NodeID
AND Phases.Phase       = 'REDUCE'
AND NodeTypes.NodeType = 'PROGRAM';

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
        PERFORM Log(
            _NodeID   := _NOPNodeID,
            _Severity := 'DEBUG2',
            _Message  := format('%s -> %s -> %s',
                Colorize(Node(_ParentNodeID),'GREEN'),
                Colorize(Node(_NOPNodeID),'RED'),
                Colorize(Node(_ChildNodeID),'GREEN')
            ),
            _SaveDOTIR := FALSE
        );
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

-- Eliminate orphan primitive nodes that have a single
-- abstract (i.e. non-primitive) child of the same type,
-- by copying the primitive value from it to the child,
-- and then kill the orphan node.
--
-- Currently, this is used to get rid of the parent IDENTIFIER-node
-- for all VARIABLE-nodes, as the before a node becomes a VARIABLE,
-- it is a IDENTIFIER-node.
LOOP
    _DidWork := FALSE;
    FOR
        _PrimitiveNodeID,
        _PrimitiveValue,
        _PrimitiveType,
        _AbstractNodeID,
        _EdgeID
    IN
    SELECT
        PrimitiveNode.NodeID AS PrimitiveNodeID,
        PrimitiveNode.PrimitiveValue,
        PrimitiveNode.PrimitiveType,
        AbstractNode.NodeID AS AbstractNodeID,
        Edges.EdgeID
    FROM Nodes           AS AbstractNode
    INNER JOIN NodeTypes AS AbstractType  ON AbstractType.NodeTypeID     = AbstractNode.NodeTypeID
    INNER JOIN Nodes     AS PrimitiveNode ON PrimitiveNode.PrimitiveType = AbstractType.PrimitiveType
    INNER JOIN Edges                      ON Edges.ParentNodeID          = PrimitiveNode.NodeID
                                         AND Edges.ChildNodeID           = AbstractNode.NodeID
    WHERE AbstractNode.ProgramID       = _ProgramID
    AND   AbstractNode.DeathPhaseID    IS NULL
    AND   PrimitiveNode.DeathPhaseID   IS NULL
    AND   Edges.DeathPhaseID           IS NULL
    AND   AbstractNode.PrimitiveValue  IS NULL
    AND   PrimitiveNode.PrimitiveValue IS NOT NULL
    AND (SELECT COUNT(*) FROM Edges WHERE Edges.DeathPhaseID IS NULL AND Edges.ParentNodeID = PrimitiveNode.NodeID) = 1
    AND (SELECT COUNT(*) FROM Edges WHERE Edges.DeathPhaseID IS NULL AND Edges.ChildNodeID  = PrimitiveNode.NodeID) = 0
    AND (SELECT COUNT(*) FROM Edges WHERE Edges.DeathPhaseID IS NULL AND Edges.ChildNodeID  = AbstractNode.NodeID)  = 1
    LOOP
        PERFORM Log(
            _NodeID   := _PrimitiveNodeID,
            _Severity := 'DEBUG2',
            _Message  := format('%s -> %s',
                Colorize(Node(_PrimitiveNodeID),'RED'),
                Colorize(Node(_AbstractNodeID),'GREEN')
            ),
            _SaveDOTIR := FALSE
        );
        IF _PrimitiveType = 'name'::regtype THEN
            -- The name for a VARIABLE is given by the PrimitiveValue
            -- for the IDENTIFIER it comes from, but we don't want to
            -- store the name as the VARIABLE's value, as it has no value yet,
            -- instead we store the name in the special NodeName column.
            -- This is similar to "debugging symbols", since we don't need the name,
            -- unless when debugging, and to support printing the name of a class.
            UPDATE Nodes SET
                PrimitiveValue = NULL,
                PrimitiveType  = NULL,
                NodeName       = _PrimitiveValue::name
            WHERE NodeID = _AbstractNodeID
            RETURNING TRUE INTO STRICT _OK;
        ELSE
            UPDATE Nodes SET
                PrimitiveValue = _PrimitiveValue,
                PrimitiveType  = _PrimitiveType
            WHERE NodeID = _AbstractNodeID
            RETURNING TRUE INTO STRICT _OK;
        END IF;

        PERFORM Kill_Edge(_EdgeID);
        PERFORM Kill_Node(_PrimitiveNodeID);
        _Killed := _Killed + 1;
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
