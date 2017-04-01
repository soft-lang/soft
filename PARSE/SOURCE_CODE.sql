CREATE OR REPLACE FUNCTION "PARSE"."SOURCE_CODE"(_NodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_GrandChildNodeID      integer;
_Nodes                 text;
_OuterNodes            text;
_ProgramID             integer;
_LanguageID            integer;
_PhaseID               integer;
_NodePattern           text;
_RegexpCapturingGroups text[];
_MatchedNodes          text;
_MatchedNode           text;
_ChildNodeTypeID       integer;
_ChildNodeType         text;
_ChildValueType        regtype;
_ParentNodeID          integer;
_ChildNodeID           integer;
_EdgeID                integer;
_ExtractNodeID         text := '^[A-Z_]+(\d+)$';
_PrologueNodeTypeID    integer;
_PrologueNodeID        integer;
_EpilogueNodeTypeID    integer;
_EpilogueNodeID        integer;
_GrowFromNodeTypeID    integer;
_GrowIntoNodeTypeID    integer;
_GrowIntoNodeType      text;
_SourceCodeCharacters  integer[];
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
INNER JOIN NodeTypes              ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
INNER JOIN Edges                  ON Edges.ChildNodeID    = Nodes.NodeID
WHERE Edges.ParentNodeID = _NodeID;

RAISE NOTICE 'Parsing nodes "%"', _Nodes;

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
    RAISE NOTICE 'Matched %', _ChildNodeType;
    IF NOT FOUND THEN
        IF _GrowIntoNodeTypeID IS NOT NULL THEN
            RAISE NOTICE 'Grow of % completed', _GrowIntoNodeTypeID;
            _EdgeID := New_Edge(
                _ProgramID    := _ProgramID,
                _ParentNodeID := _ChildNodeID,
                _ChildNodeID  := _GrandChildNodeID
            );
            RAISE NOTICE 'FINAL GROW EDGE % -> % EdgeID %', _ChildNodeID, _GrandChildNodeID, _EdgeID;
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

    _MatchedNodes := Get_Capturing_Group(_Nodes, _NodePattern);

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
        _ParentNodeID := Get_Capturing_Group(_MatchedNode, _ExtractNodeID)::integer;

        IF _GrowIntoNodeType IS NULL OR _MatchedNode ~ ('^'||_GrowIntoNodeType||'\d+$') THEN
            _EdgeID := New_Edge(
                _ProgramID    := _ProgramID,
                _ParentNodeID := _ParentNodeID,
                _ChildNodeID  := _ChildNodeID
            );
            RAISE NOTICE 'NEW EDGE % -> % EdgeID %', _ParentNodeID, _ChildNodeID, _EdgeID;
        ELSIF _GrowIntoNodeType IS NOT NULL THEN
            SELECT Kill_Edge(EdgeID)                           INTO STRICT _OK                   FROM Edges WHERE ChildNodeID = _ParentNodeID;
            SELECT Kill_Node(NodeID)                           INTO STRICT _OK                   FROM Nodes WHERE NodeID      = _ParentNodeID;
            SELECT _SourceCodeCharacters||SourceCodeCharacters INTO STRICT _SourceCodeCharacters FROM Nodes WHERE NodeID      = _ParentNodeID;
            RAISE NOTICE 'KILL NODE %', _ParentNodeID;
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
