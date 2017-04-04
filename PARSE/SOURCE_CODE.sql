CREATE OR REPLACE FUNCTION "PARSE"."SOURCE_CODE"(_NodeID integer)
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
_SourceCodeCharacters       integer[];
_MatchedNode                text;
_ParentNodeID               integer;
_EpilogueNodeID             integer;
_OK                         boolean;
_AnyNodePattern    CONSTANT text := '(?:^| )[A-Z_]+(\d+)';
_SingleNodePattern CONSTANT text := '^[A-Z_]+(\d+)$';
_ProgramNodeType            text;
_IllegalNodePattern         text;
_IllegalNodePatterns        text[];
_Children                   integer;
_Parents                    integer;
_Killed                     integer;
_LogSeverity                severity;
_NodeSeverity               severity;
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
WHERE Nodes.NodeID = _NodeID
AND Phases.Phase       = 'PARSE'
AND NodeTypes.NodeType = 'SOURCE_CODE'
AND Nodes.TerminalType = 'text'::regtype
AND Nodes.DeathPhaseID IS NULL;

SELECT string_agg(format('%s%s',NodeTypes.NodeType,Nodes.NodeID), ' ' ORDER BY Nodes.NodeID)
INTO _Nodes
FROM Nodes
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
INNER JOIN Edges     ON Edges.ChildNodeID    = Nodes.NodeID
WHERE Edges.ParentNodeID = _NodeID
AND   Nodes.DeathPhaseID IS NULL
AND   Edges.DeathPhaseID IS NULL;

SELECT NodeType INTO STRICT _ProgramNodeType FROM NodeTypes WHERE LanguageID = _LanguageID ORDER BY NodeTypeID DESC LIMIT 1;

PERFORM Log(
    _NodeID   := _NodeID,
    _Severity := 'DEBUG1',
    _Message  := format('Parsing %s from nodes %s', Colorize(_ProgramNodeType, 'CYAN'), Colorize(_Nodes, 'MAGENTA'))
);

_Children := 0;
_Parents  := 0;
_Killed   := 0;
LOOP
    SELECT
        NodeTypes.NodeTypeID,
        NodeTypes.NodeType,
        NodeTypes.TerminalType,
        NodeTypes.NodePattern,
        Expand_Token_Groups(NodeTypes.NodePattern, NodeTypes.LanguageID),
        NodeTypes.PrologueNodeTypeID,
        NodeTypes.EpilogueNodeTypeID,
        NodeTypes.GrowFromNodeTypeID,
        GrowFromNodeType.NodeType,
        NodeTypes.NodeSeverity
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
        _NodeSeverity
    FROM NodeTypes
    LEFT JOIN NodeTypes AS GrowFromNodeType ON GrowFromNodeType.NodeTypeID = NodeTypes.GrowFromNodeTypeID
    WHERE NodeTypes.LanguageID = _LanguageID
    AND _Nodes ~ Expand_Token_Groups(NodeTypes.NodePattern, NodeTypes.LanguageID)
    AND NodeTypes.GrowIntoNodeTypeID IS NOT DISTINCT FROM _GrowIntoNodeTypeID
    ORDER BY NodeTypes.NodeTypeID
    LIMIT 1;
    IF NOT FOUND THEN
        IF _Nodes ~ ('^'||_GrowIntoNodeType||'\d+$') THEN
            PERFORM Log(
                _NodeID   := _NodeID,
                _Severity := 'DEBUG2',
                _Message  := format('Done growing %s', Colorize(_GrowIntoNodeType))
            );
            PERFORM New_Edge(
                _ProgramID    := _ProgramID,
                _ParentNodeID := _ChildNodeID,
                _ChildNodeID  := _GrandChildNodeID
            );
            _Nodes              := _OuterNodes;
            _OuterNodes         := NULL;
            _GrowIntoNodeTypeID := NULL;
            _GrowIntoNodeType   := NULL;
            _GrandChildNodeID   := NULL;
            CONTINUE;
        ELSIF _Nodes ~ format('^%s\d+$',_ProgramNodeType) THEN
            PERFORM Log(
                _NodeID   := _NodeID,
                _Severity := 'INFO',
                _Message  := format('OK, %s children born with %s valuable parents and killed %s valueless parents', _Children, _Parents, _Killed)
            );
            RETURN TRUE;
        ELSE
            _IllegalNodePatterns  := NULL;
            _SourceCodeCharacters := NULL;
            FOREACH _IllegalNodePattern IN ARRAY regexp_split_to_array(_Nodes, format('(^| )%s\d+( |$)',_ProgramNodeType)) LOOP
                IF _IllegalNodePattern = '' THEN
                    CONTINUE;
                END IF;
                _IllegalNodePatterns := _IllegalNodePatterns || _IllegalNodePattern;
                SELECT _SourceCodeCharacters || ARRAY(
                    SELECT unnest(SourceCodeCharacters)
                    FROM Nodes
                    WHERE SourceCodeCharacters IS NOT NULL
                    AND NodeID IN (
                        SELECT DISTINCT Get_Parent_Nodes(_NodeID := regexp_matches[1]::integer) AS NodeID FROM regexp_matches(_IllegalNodePattern,_AnyNodePattern,'g')
                    )
                ) INTO STRICT _SourceCodeCharacters;
            END LOOP;
            RAISE EXCEPTION E'Illegal node patterns (%): %\n%',
                array_length(_IllegalNodePatterns,1),
                array_to_string(_IllegalNodePatterns, ', '),
                Highlight_Code(
                    _Text                 := Get_Source_Code(_ProgramID),
                    _SourceCodeCharacters := _SourceCodeCharacters,
                    _Color                := 'RED'
                )
            USING HINT = 'Define a node type with a catch-all node pattern with NodeSeverity e.g. ERROR and a suitable name e.g. UNPARSEABLE';
        END IF;
    END IF;

    _ChildNodeID := New_Node(
        _ProgramID  := _ProgramID,
        _NodeTypeID := _ChildNodeTypeID
    );
    _Children := _Children + 1;

    _MatchedNodes := Get_Capturing_Group(_String := _Nodes, _Pattern := _ExpandedNodePattern, _Strict := FALSE);

    _ChildNodeString := COALESCE(_GrowIntoNodeType,_ChildNodeType)||_ChildNodeID;

    PERFORM Log(
        _NodeID   := _NodeID,
        _Severity := COALESCE(_NodeSeverity,'DEBUG2'),
        _Message  := format('%s <- %s <- %s <- %s',
            Colorize(_ChildNodeString || CASE WHEN _GrowIntoNodeType IS NOT NULL THEN '('||_ChildNodeType||')' ELSE '' END, 'GREEN'),
            Colorize(_NodePattern, 'CYAN'),
            Colorize(_MatchedNodes, 'BLUE'),
            One_Line(Get_Source_Code_Fragment(_MatchedNodes, 'MAGENTA'))
        )
    );

    _Nodes := regexp_replace(_Nodes, _MatchedNodes, _ChildNodeString);

    IF _GrowFromNodeTypeID IS NOT NULL AND _MatchedNodes !~ ('^'||_GrowFromNodeType||'\d+$') THEN
        PERFORM Log(
            _NodeID   := _NodeID,
            _Severity := 'DEBUG2',
            _Message  := format('Begin growing %s', Colorize(_GrowFromNodeType))
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
            _NodeTypeID := _PrologueNodeTypeID
        );
        PERFORM New_Edge(
            _ProgramID    := _ProgramID,
            _ParentNodeID := _PrologueNodeID,
            _ChildNodeID  := _ChildNodeID
        );
        _Parents := _Parents + 1;
    END IF;

    _SourceCodeCharacters := NULL;
    FOREACH _MatchedNode IN ARRAY regexp_split_to_array(_MatchedNodes, ' ') LOOP
        _ParentNodeID := Get_Capturing_Group(_String := _MatchedNode, _Pattern := _SingleNodePattern, _Strict := TRUE)::integer;

        IF _GrowIntoNodeType IS NULL OR _MatchedNode ~ ('^'||_GrowIntoNodeType||'\d+$') THEN
            PERFORM New_Edge(
                _ProgramID    := _ProgramID,
                _ParentNodeID := _ParentNodeID,
                _ChildNodeID  := _ChildNodeID
            );
            _Parents := _Parents + 1;
        ELSIF _GrowIntoNodeType IS NOT NULL THEN
            SELECT Kill_Edge(EdgeID)                           INTO STRICT _OK                   FROM Edges WHERE ChildNodeID = _ParentNodeID;
            SELECT Kill_Node(NodeID)                           INTO STRICT _OK                   FROM Nodes WHERE NodeID      = _ParentNodeID;
            SELECT _SourceCodeCharacters||SourceCodeCharacters INTO STRICT _SourceCodeCharacters FROM Nodes WHERE NodeID      = _ParentNodeID;
            _Killed := _Killed + 1;
        ELSE
            RAISE EXCEPTION 'How did we end up here?!';
        END IF;
    END LOOP;

    IF _EpilogueNodeTypeID IS NOT NULL THEN
        _EpilogueNodeID := New_Node(
            _ProgramID  := _ProgramID,
            _NodeTypeID := _PrologueNodeTypeID
        );
        PERFORM New_Edge(
            _ProgramID    := _ProgramID,
            _ParentNodeID := _EpilogueNodeID,
            _ChildNodeID  := _ChildNodeID
        );
        _Parents := _Parents + 1;
    END IF;

    UPDATE Nodes SET SourceCodeCharacters = _SourceCodeCharacters WHERE NodeID IN (_PrologueNodeID, _ChildNodeID, _EpilogueNodeID);

END LOOP;

RETURN TRUE;
END;
$$;
