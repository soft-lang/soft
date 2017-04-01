CREATE OR REPLACE FUNCTION "PARSE"."SOURCE_CODE"(_NodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID             integer;
_LanguageID            integer;
_PhaseID               integer;
_Nodes                 text;
_ChildNodeTypeID       integer;
_ChildNodeType         text;
_ChildValueType        regtype;
_NodePattern           text;
_PrologueNodeTypeID    integer;
_EpilogueNodeTypeID    integer;
_GrowFromNodeTypeID    integer;
_GrowIntoNodeType      text;
_OuterNodes            text;
_GrowIntoNodeTypeID    integer;
_GrandChildNodeID      integer;
_ChildNodeID           integer;
_MatchedNodes          text;
_PrologueNodeID        integer;
_SourceCodeCharacters  integer[];
_MatchedNode           text;
_ParentNodeID          integer;
_EpilogueNodeID        integer;
_OK                    boolean;
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

LOOP
    SELECT
        NodeTypes.NodeTypeID,
        NodeTypes.NodeType,
        NodeTypes.TerminalType,
        NodeTypes.NodePattern,
        NodeTypes.PrologueNodeTypeID,
        NodeTypes.EpilogueNodeTypeID,
        NodeTypes.GrowFromNodeTypeID,
        GrowIntoNodeType.NodeType
    INTO
        _ChildNodeTypeID,
        _ChildNodeType,
        _ChildValueType,
        _NodePattern,
        _PrologueNodeTypeID,
        _EpilogueNodeTypeID,
        _GrowFromNodeTypeID,
        _GrowIntoNodeType
    FROM NodeTypes
    LEFT JOIN NodeTypes AS GrowIntoNodeType ON GrowIntoNodeType.NodeTypeID = NodeTypes.GrowIntoNodeTypeID
    WHERE NodeTypes.LanguageID = _LanguageID
    AND _Nodes ~ NodeTypes.NodePattern
    AND NodeTypes.GrowIntoNodeTypeID IS NOT DISTINCT FROM _GrowIntoNodeTypeID
    ORDER BY NodeTypes.NodeTypeID
    LIMIT 1;
    IF NOT FOUND THEN
        IF _GrowIntoNodeTypeID IS NOT NULL THEN
            PERFORM New_Edge(
                _ProgramID    := _ProgramID,
                _ParentNodeID := _ChildNodeID,
                _ChildNodeID  := _GrandChildNodeID
            );
            _Nodes              := _OuterNodes;
            _OuterNodes         := NULL;
            _GrowIntoNodeTypeID := NULL;
            _GrandChildNodeID   := NULL;
            CONTINUE;
        ELSE
            RETURN TRUE;
        END IF;
    END IF;

    _ChildNodeID := New_Node(
        _ProgramID  := _ProgramID,
        _NodeTypeID := _ChildNodeTypeID
    );

    _MatchedNodes := Get_Capturing_Group(_String := _Nodes, _Pattern := _NodePattern, _Strict := FALSE);

    _Nodes := regexp_replace(_Nodes, _MatchedNodes, COALESCE(_GrowIntoNodeType,_ChildNodeType)||_ChildNodeID);

    IF _GrowFromNodeTypeID IS NOT NULL THEN
        _GrandChildNodeID   := _ChildNodeID;
        _ChildNodeID        := NULL;
        _GrowIntoNodeTypeID := _GrowFromNodeTypeID;
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
        _ParentNodeID := Get_Capturing_Group(_String := _MatchedNode, _Pattern := '^[A-Z_]+(\d+)$', _Strict := TRUE)::integer;

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
