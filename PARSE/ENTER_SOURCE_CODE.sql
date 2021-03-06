CREATE OR REPLACE FUNCTION "PARSE"."ENTER_SOURCE_CODE"(_NodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID                  integer;
_LanguageID                 integer;
_Nodes                      text;
_ChildNodeTypeID            integer;
_ChildNodeType              text;
_ChildValueType             regtype;
_NodePattern                text;
_ExpandedNodePattern        text;
_PrologueNodeTypeID         integer;
_EpilogueNodeTypeID         integer;
_GrowFromNodeTypeID         integer;
_GrowFromNodeType           text;
_GrowIntoNodeType           text;
_OuterNodes                 text;
_GrowIntoNodeTypeID         integer;
_GrandChildNodeID           integer;
_ChildNodeID                integer;
_ChildNodeString            text;
_MatchedNodes               text;
_PrologueNodeID             integer;
_MatchedNode                text;
_ParentNodeID               integer;
_EpilogueNodeID             integer;
_OK                         boolean;
_AnyNodePattern    CONSTANT text := '<[A-Z_]+(\d+)>';
_SingleNodePattern CONSTANT text := '^<[A-Z_]+(\d+)>$';
_ProgramNodeType            text;
_ProgramNodeTypeID          integer;
_Children                   integer;
_Parents                    integer;
_Killed                     integer;
_NodeSeverity               severity;
_ProgramNodePattern         text;
_ProgramNodeID              integer;
_EdgeID                     integer;
_Matches                    integer;
_LeftNodeType               text;
_RightNodeType              text;
BEGIN

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
AND Phases.Phase       = 'PARSE'
AND NodeTypes.NodeType = 'SOURCE_CODE'
AND Nodes.PrimitiveType = 'text'::regtype
AND Nodes.DeathPhaseID IS NULL;

SELECT string_agg(format('<%s%s>',NodeTypes.NodeType,Nodes.NodeID), '' ORDER BY Nodes.NodeID)
INTO _Nodes
FROM Nodes
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
INNER JOIN Edges     ON Edges.ParentNodeID   = Nodes.NodeID
WHERE Edges.ChildNodeID  = _NodeID
AND   Nodes.DeathPhaseID IS NULL
AND   Edges.DeathPhaseID IS NULL;

-- Freeing tokens from the source code node so that they can be parsed
PERFORM Kill_Edge(EdgeID) FROM Edges WHERE DeathPhaseID IS NULL AND ChildNodeID = _NodeID;

SELECT NodeTypeID, NodeType INTO STRICT _ProgramNodeTypeID, _ProgramNodeType FROM NodeTypes WHERE LanguageID = _LanguageID ORDER BY NodeTypeID DESC LIMIT 1;

_ProgramNodePattern := format('^<%s(\d+)>$',_ProgramNodeType);

UPDATE NodeTypes
SET ExpandedNodePattern = Expand_Node_Pattern(NodePattern, LanguageID)
WHERE LanguageID        = _LanguageID
AND NodePattern         IS NOT NULL
AND ExpandedNodePattern IS NULL;

IF _Nodes IS NULL THEN
    -- Empty program
    _ProgramNodeID := New_Node(
        _ProgramID  := _ProgramID,
        _NodeTypeID := _ProgramNodeTypeID,
        _Walkable   := TRUE
    );
    PERFORM Log(
        _NodeID   := _NodeID,
        _Severity := 'INFO',
        _Message  := format('Empty program')
    );
    PERFORM Set_Program_Node(_ProgramNodeID);
    PERFORM Kill_Node(_NodeID);
    RETURN TRUE;
END IF;

PERFORM Log(
    _NodeID    := _NodeID,
    _Severity  := 'DEBUG1',
    _Message   := format('Parsing %s from nodes %s', Colorize(_ProgramNodeType, 'CYAN'), Colorize(_Nodes, 'MAGENTA')),
    _SaveDOTIR := TRUE
);

_Children := 0;
_Parents  := 0;
_Killed   := 0;
LOOP

    PERFORM Log(
        _NodeID   := _NodeID,
        _Severity := 'DEBUG5',
        _Message  := format('Parsing %s', _Nodes)
    );

    SELECT
        NodeTypes.NodeTypeID,
        NodeTypes.NodeType,
        NodeTypes.PrimitiveType,
        NodeTypes.NodePattern,
        NodeTypes.ExpandedNodePattern,
        NodeTypes.PrologueNodeTypeID,
        NodeTypes.EpilogueNodeTypeID,
        NodeTypes.GrowFromNodeTypeID,
        GrowFromNodeType.NodeType,
        NodeTypes.NodeSeverity,
        COUNT(*) OVER ()
    INTO
        _ChildNodeTypeID,
        _ChildNodeType,
        _ChildValueType,
        _NodePattern,
        _ExpandedNodePattern,
        _PrologueNodeTypeID,
        _EpilogueNodeTypeID,
        _GrowFromNodeTypeID,
        _GrowFromNodeType,
        _NodeSeverity,
        _Matches
    FROM NodeTypes
    LEFT JOIN NodeTypes AS GrowFromNodeType ON GrowFromNodeType.NodeTypeID = NodeTypes.GrowFromNodeTypeID
    WHERE NodeTypes.LanguageID = _LanguageID
    AND _Nodes ~ NodeTypes.ExpandedNodePattern
    AND NodeTypes.GrowIntoNodeTypeID IS NOT DISTINCT FROM _GrowIntoNodeTypeID
    ORDER BY
        Precedence(NodeTypes.NodeTypeID),
        -- If multiple node pattern with the same precedence matches,
        -- then select the node pattern that matches first:
        strpos(_Nodes, substring(_Nodes from NodeTypes.ExpandedNodePattern))
    LIMIT 1;
    IF NOT FOUND THEN
        IF _Nodes ~ ('^<'||_GrowIntoNodeType||'\d+>$') THEN
            PERFORM Log(
                _NodeID   := _NodeID,
                _Severity := 'DEBUG2',
                _Message  := format('Done growing %s', Colorize(_GrowIntoNodeType))
            );
            PERFORM New_Edge(
                _ParentNodeID := _ChildNodeID,
                _ChildNodeID  := _GrandChildNodeID
            );
            _Nodes              := _OuterNodes;
            _OuterNodes         := NULL;
            _GrowIntoNodeTypeID := NULL;
            _GrowIntoNodeType   := NULL;
            _GrandChildNodeID   := NULL;
            CONTINUE;
        ELSIF _Nodes ~ _ProgramNodePattern THEN
            _ProgramNodeID := Get_Capturing_Group(_String := _Nodes, _Pattern := _ProgramNodePattern, _Strict := TRUE)::integer;
            PERFORM Log(
                _NodeID   := _NodeID,
                _Severity := 'INFO',
                _Message  := format('OK, %s children born with %s valuable parents and killed %s valueless parents. Setting current NodeID to %s', _Children, _Parents, _Killed, _ProgramNodeID)
            );
            PERFORM Set_Program_Node(_ProgramNodeID);
            PERFORM Kill_Node(_NodeID);
            RETURN TRUE;
        ELSE
            RAISE EXCEPTION E'Illegal node pattern NodeID %: %',
                _NodeID,
                _Nodes
            USING HINT = 'Define a node type with a catch-all node pattern with NodeSeverity e.g. ERROR and a suitable name e.g. UNPARSEABLE';
        END IF;
    END IF;

    _ChildNodeID := New_Node(
        _ProgramID  := _ProgramID,
        _NodeTypeID := _ChildNodeTypeID
    );
    _Children := _Children + 1;

    _MatchedNodes := Get_Capturing_Group(_String := _Nodes, _Pattern := _ExpandedNodePattern, _Strict := FALSE);

    _ChildNodeString := format('<%s%s>', COALESCE(_GrowIntoNodeType,_ChildNodeType), _ChildNodeID);

    PERFORM Set_Program_Node(_NodeID := _ChildNodeID);

    _LeftNodeType  := (regexp_matches(_Nodes, format('<([A-Z]+)\d+>%s', _MatchedNodes)))[1];
    _RightNodeType := (regexp_matches(_Nodes, format('%s<([A-Z]+)\d+>', _MatchedNodes)))[1];
    IF NOT EXISTS (
        SELECT 1 FROM Contexts
        WHERE LeftNodeType  IS NOT DISTINCT FROM _LeftNodeType
        AND   NodeType = _ChildNodeType
        AND   RightNodeType IS NOT DISTINCT FROM _RightNodeType
    ) THEN
        INSERT INTO Contexts ( LeftNodeType,       NodeType,  RightNodeType)
        VALUES               (_LeftNodeType, _ChildNodeType, _RightNodeType)
        RETURNING TRUE INTO STRICT _OK;
    END IF;


    IF _NodeSeverity IS NOT NULL
    AND _GrowIntoNodeTypeID IS NULL
    THEN
        _Nodes := regexp_replace(_Nodes, _MatchedNodes, '');
    ELSE
        _Nodes := regexp_replace(_Nodes, _MatchedNodes, _ChildNodeString);
    END IF;

    IF _GrowFromNodeTypeID IS NOT NULL AND _MatchedNodes !~ ('^<'||_GrowFromNodeType||'\d+>$') THEN
        PERFORM Log(
            _NodeID   := _NodeID,
            _Severity := 'DEBUG2',
            _Message  := format('Begin growing %s from %s', Colorize(_GrowFromNodeType), Colorize(_ChildNodeType))
        );
        _GrandChildNodeID   := _ChildNodeID;
        _ChildNodeID        := NULL;
        _GrowIntoNodeTypeID := _GrowFromNodeTypeID;
        _GrowIntoNodeType   := _GrowFromNodeType;
        _OuterNodes         := _Nodes;
        _Nodes              := _MatchedNodes;
        CONTINUE;
    END IF;

    IF _PrologueNodeTypeID IS NOT NULL THEN
        _PrologueNodeID := New_Node(
            _ProgramID  := _ProgramID,
            _NodeTypeID := _PrologueNodeTypeID,
            _Walkable   := FALSE
        );
        PERFORM New_Edge(
            _ParentNodeID := _PrologueNodeID,
            _ChildNodeID  := _ChildNodeID
        );
        _Parents := _Parents + 1;
    END IF;

    FOREACH _MatchedNode IN ARRAY regexp_split_to_array(_MatchedNodes, '(?=<)') LOOP
        _ParentNodeID := Get_Capturing_Group(_String := _MatchedNode, _Pattern := _SingleNodePattern, _Strict := TRUE)::integer;

        _EdgeID := New_Edge(
            _ParentNodeID := _ParentNodeID,
            _ChildNodeID  := _ChildNodeID
        );
        IF _GrowIntoNodeType IS NULL OR _MatchedNode ~ ('^<'||_GrowIntoNodeType||'\d+>$') THEN
            _Parents := _Parents + 1;
        ELSIF _GrowIntoNodeType IS NOT NULL
        AND NOT EXISTS (SELECT 1 FROM Edges WHERE ChildNodeID = _ParentNodeID AND DeathPhaseID IS NULL)
        AND _NodeSeverity IS NULL
        THEN
            PERFORM Kill_Edge(_EdgeID);
            PERFORM Kill_Node(_ParentNodeID);
            _Killed := _Killed + 1;
        END IF;
    END LOOP;

    IF _NodeSeverity IS NOT NULL THEN
        PERFORM Error(
            _NodeID    := _ChildNodeID,
            _ErrorType := _ChildNodeType
        );
    END IF;

    PERFORM Log(
        _NodeID   := _ChildNodeID,
        _Severity := 'DEBUG2',
        _Message  := format('%s%s <- %s <- %s',
            Colorize(_ChildNodeString || CASE WHEN _GrowIntoNodeType IS NOT NULL THEN '('||_ChildNodeType||')' ELSE '' END, 'GREEN'),
            CASE WHEN _NodeSeverity = 'DEBUG5' THEN ' <- ' || Colorize(_NodePattern, 'CYAN') END,
            Colorize(_MatchedNodes, 'BLUE'),
            One_Line(Get_Source_Code_Fragment(_MatchedNodes, 'MAGENTA'))
        ),
        _SaveDOTIR := TRUE
    );

    IF _EpilogueNodeTypeID IS NOT NULL THEN
        _EpilogueNodeID := New_Node(
            _ProgramID  := _ProgramID,
            _NodeTypeID := _EpilogueNodeTypeID
        );
        PERFORM New_Edge(
            _ParentNodeID := _EpilogueNodeID,
            _ChildNodeID  := _ChildNodeID
        );
        _Parents := _Parents + 1;
    END IF;
END LOOP;

RETURN TRUE;
END;
$$;
