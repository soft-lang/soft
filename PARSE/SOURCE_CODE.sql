CREATE OR REPLACE FUNCTION "PARSE"."SOURCE_CODE"(_NodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID                  integer;
_LanguageID                 integer;
_PhaseID                    integer;
_Nodes                      text;
_ChildNodeTypeID            integer;
_ChildNodeType              text;
_ChildValueType             regtype;
_NodePattern                text;
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
BEGIN

SELECT
    Nodes.ProgramID,
    NodeTypes.LanguageID,
    Programs.PhaseID
INTO STRICT
    _ProgramID,
    _LanguageID,
    _PhaseID
FROM Nodes
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
INNER JOIN Programs  ON Programs.ProgramID   = Nodes.ProgramID
INNER JOIN Phases    ON Phases.PhaseID       = Programs.PhaseID
WHERE Nodes.NodeID = _NodeID
AND Phases.Phase       = 'PARSE'
AND NodeTypes.NodeType = 'SOURCE_CODE'
AND Nodes.TerminalType = 'text'::regtype;

SELECT string_agg(format('%s%s',NodeTypes.NodeType,Nodes.NodeID), ' ' ORDER BY Nodes.NodeID)
INTO _Nodes
FROM Nodes
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
INNER JOIN Edges     ON Edges.ChildNodeID    = Nodes.NodeID
WHERE Edges.ParentNodeID = _NodeID;

PERFORM Log(
    _NodeID   := _NodeID,
    _Severity := 'DEBUG1',
    _Message  := format('Parsing nodes: %s', _Nodes)
);

LOOP
    SELECT
        NodeTypes.NodeTypeID,
        NodeTypes.NodeType,
        NodeTypes.TerminalType,
        NodeTypes.NodePattern,
        NodeTypes.PrologueNodeTypeID,
        NodeTypes.EpilogueNodeTypeID,
        NodeTypes.GrowFromNodeTypeID,
        GrowFromNodeType.NodeType
    INTO
        _ChildNodeTypeID,
        _ChildNodeType,
        _ChildValueType,
        _NodePattern,
        _PrologueNodeTypeID,
        _EpilogueNodeTypeID,
        _GrowFromNodeTypeID,
        _GrowFromNodeType
    FROM NodeTypes
    LEFT JOIN NodeTypes AS GrowFromNodeType ON GrowFromNodeType.NodeTypeID = NodeTypes.GrowFromNodeTypeID
    WHERE NodeTypes.LanguageID = _LanguageID
    AND _Nodes ~ NodeTypes.NodePattern
    AND NodeTypes.GrowIntoNodeTypeID IS NOT DISTINCT FROM _GrowIntoNodeTypeID
    ORDER BY NodeTypes.NodeTypeID
    LIMIT 1;
    IF NOT FOUND THEN
        IF _Nodes ~ ('^'||_GrowIntoNodeType||'\d+$') THEN
            PERFORM Log(
                _NodeID   := _NodeID,
                _Severity := 'DEBUG2',
                _Message  := format('Grew %s', Colorize(_GrowIntoNodeType))
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
        ELSIF _Nodes ~ _SingleNodePattern THEN
            PERFORM Log(
                _NodeID   := _NodeID,
                _Severity := 'INFO',
                _Message  := 'OK'
            );
            RETURN TRUE;
        ELSE
            SELECT NodeType INTO STRICT _ProgramNodeType FROM NodeTypes WHERE LanguageID = _LanguageID ORDER BY NodeTypeID DESC LIMIT 1;
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
            PERFORM Log(
                _NodeID               := _NodeID,
                _Severity             := 'ERROR',
                _Message              := format(E'Illegal node patterns (%s): %s', array_length(_IllegalNodePatterns,1), array_to_string(_IllegalNodePatterns, ', ')),
                _SourceCodeCharacters := _SourceCodeCharacters
            );
            RETURN FALSE;
        END IF;
    END IF;

    _ChildNodeID := New_Node(
        _ProgramID  := _ProgramID,
        _NodeTypeID := _ChildNodeTypeID
    );

    _MatchedNodes := Get_Capturing_Group(_String := _Nodes, _Pattern := _NodePattern, _Strict := FALSE);

    _ChildNodeString := COALESCE(_GrowIntoNodeType,_ChildNodeType)||_ChildNodeID;

    PERFORM Log(
        _NodeID   := _NodeID,
        _Severity := 'DEBUG3',
        _Message  := format('%s <- %s',
            Colorize(CASE
            WHEN _GrowIntoNodeType IS NOT NULL THEN _ChildNodeString || '(' || _ChildNodeType || ')'
            ELSE _ChildNodeString
            END, 'CYAN'),
            regexp_replace(_Nodes, _MatchedNodes, Colorize(_MatchedNodes, 'MAGENTA'))
        )
    );

    _Nodes := regexp_replace(_Nodes, _MatchedNodes, _ChildNodeString);

    IF _GrowFromNodeTypeID IS NOT NULL AND _MatchedNodes !~ ('^'||_GrowFromNodeType||'\d+$') THEN
        PERFORM Log(
            _NodeID   := _NodeID,
            _Severity := 'DEBUG2',
            _Message  := format('Growing %s', Colorize(_GrowFromNodeType))
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
        ELSIF _GrowIntoNodeType IS NOT NULL THEN
            SELECT Kill_Edge(EdgeID)                           INTO STRICT _OK                   FROM Edges WHERE ChildNodeID = _ParentNodeID;
            SELECT Kill_Node(NodeID)                           INTO STRICT _OK                   FROM Nodes WHERE NodeID      = _ParentNodeID;
            SELECT _SourceCodeCharacters||SourceCodeCharacters INTO STRICT _SourceCodeCharacters FROM Nodes WHERE NodeID      = _ParentNodeID;
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
    END IF;

    UPDATE Nodes SET SourceCodeCharacters = _SourceCodeCharacters WHERE NodeID IN (_PrologueNodeID, _ChildNodeID, _EpilogueNodeID);

END LOOP;

RETURN TRUE;
END;
$$;
