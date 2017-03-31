CREATE OR REPLACE FUNCTION "PARSE"."SOURCE_CODE"(_NodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
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
_Input                 text;
_ExtractNodeID         text := '^[A-Z_]+(\d+)$';
_PrologueNodeTypeID    integer;
_PrologueNodeID        integer;
_EpilogueNodeTypeID    integer;
_EpilogueNodeID        integer;
_Chars                 integer[];
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

TerminalType       regtype,
NodeGroup          text,
Literal            text,
LiteralLength      integer,
LiteralPattern     text,
NodePattern        text,
PrologueNodeTypeID integer,
EpilogueNodeTypeID integer,
GrowFromNodeTypeID integer,
GrowIntoNodeTypeID integer,


SELECT string_agg(format('%s%s',NodeTypes.NodeType,Nodes.NodeID), ' ' ORDER BY Nodes.NodeID)
INTO _Nodes
FROM Nodes
INNER JOIN NodeTypes              ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
INNER JOIN Edges                  ON Edges.ChildNodeID    = Nodes.NodeID
WHERE Edges.ParentNodeID = _SourceCodeNodeID
AND NOT Nodes.Deleted
AND NOT Edges.Deleted;

LOOP
    RAISE NOTICE '% %', _Output, _Nodes;
    SELECT
        NodeTypes.NodeTypeID,
        NodeTypes.NodeType,
        NodeTypes.ValueType,
        NodeTypes.NodePattern,
        NodeTypes.Input,
        Prologue.NodeTypeID,
        Epilogue.NodeTypeID
    INTO
        _ChildNodeTypeID,
        _ChildNodeType,
        _ChildValueType,
        _NodePattern,
        _Input,
        _PrologueNodeTypeID,
        _EpilogueNodeTypeID
    FROM NodeTypes
    LEFT JOIN NodeTypes AS Prologue ON Prologue.NodeType = NodeTypes.Prologue
    LEFT JOIN NodeTypes AS Epilogue ON Epilogue.NodeType = NodeTypes.Epilogue
    WHERE NodeTypes.LanguageID = _LanguageID
    AND _Nodes ~ NodeTypes.NodePattern
    AND NodeTypes.Output IS NOT DISTINCT FROM _Output
    ORDER BY NodeTypes.NodeTypeID
    LIMIT 1;
    IF NOT FOUND THEN
        RETURN TRUE;
    END IF;

    _ChildNodeID := New_Node(_ChildNodeTypeID);
    _RegexpCapturingGroups := regexp_matches(_Nodes, _NodePattern);
    IF (array_length(_RegexpCapturingGroups,1) = 1) IS NOT TRUE THEN
        RAISE EXCEPTION 'Regexp % did not return a single capturing group from "%": %', _NodePattern, _Nodes, _RegexpCapturingGroups;
    END IF;
    _MatchedNodes := _RegexpCapturingGroups[1];
    _RegexpCapturingGroups := NULL;

    RAISE NOTICE 'REPLACE % WITH %', _MatchedNodes, COALESCE(_Output,_ChildNodeType)||_ChildNodeID;
    _Nodes := regexp_replace(_Nodes, _MatchedNodes, COALESCE(_Output,_ChildNodeType)||_ChildNodeID);

    IF _PrologueNodeTypeID IS NOT NULL THEN
        INSERT INTO Edges (ParentNodeID, ChildNodeID) VALUES (New_Node(_PrologueNodeTypeID), _ChildNodeID) RETURNING ParentNodeID, EdgeID INTO STRICT _PrologueNodeID, _EdgeID;
    END IF;

    _Chars := NULL;
    FOREACH _MatchedNode IN ARRAY regexp_split_to_array(_MatchedNodes, ' ') LOOP
        _RegexpCapturingGroups := regexp_matches(_MatchedNode, _ExtractNodeID);
        IF (array_length(_RegexpCapturingGroups,1) = 1) IS NOT TRUE THEN
            RAISE EXCEPTION 'Regexp % did not return a single capturing group from "%": %', _ExtractNodeID, _MatchedNode, _RegexpCapturingGroups;
        END IF;

        _ParentNodeID := _RegexpCapturingGroups[1]::integer;

        IF _Input IS NOT NULL AND _Output IS NULL THEN
            -- Not handled here
        ELSIF _Input IS NULL OR _MatchedNode ~ ('^'||_Input||'\d+$') THEN
            INSERT INTO Edges ( ParentNodeID,  ChildNodeID)
            VALUES            (_ParentNodeID, _ChildNodeID)
            RETURNING    EdgeID
            INTO STRICT _EdgeID;
            RAISE NOTICE 'NEW EDGE % -> % EdgeID %', _ParentNodeID, _ChildNodeID, _EdgeID;
        ELSIF _Input IS NOT NULL AND _Output IS NOT NULL THEN
            UPDATE Edges SET Deleted = TRUE WHERE NOT Deleted AND ChildNodeID = _ParentNodeID RETURNING TRUE INTO STRICT _OK;
            UPDATE Nodes SET Deleted = TRUE WHERE NOT Deleted AND NodeID      = _ParentNodeID RETURNING TRUE INTO STRICT _OK;
            SELECT _Chars||Chars INTO STRICT _Chars FROM Nodes WHERE NodeID = _ParentNodeID;
        ELSE
            RAISE EXCEPTION 'How did we end up here?!';
        END IF;
    END LOOP;

    IF _EpilogueNodeTypeID IS NOT NULL THEN
        INSERT INTO Edges (ParentNodeID, ChildNodeID) VALUES (New_Node(_EpilogueNodeTypeID), _ChildNodeID) RETURNING ParentNodeID, EdgeID INTO STRICT _EpilogueNodeID, _EdgeID;
    END IF;

    UPDATE Nodes SET Chars = _Chars WHERE NodeID IN (_PrologueNodeID, _ChildNodeID, _EpilogueNodeID);

    IF _Input IS NOT NULL AND _Output IS NULL THEN
        PERFORM Parse(_LanguageID, _MatchedNodes, _Input, _ChildNodeID);
    END IF;

    IF _Nodes ~ ('^'||_Input||'\d+$') THEN
        IF _GrandChildNodeID IS NOT NULL THEN
            _RegexpCapturingGroups := regexp_matches(_Nodes, _ExtractNodeID);
            IF (array_length(_RegexpCapturingGroups,1) = 1) IS NOT TRUE THEN
                RAISE EXCEPTION 'Regexp % did not return a single capturing group from "%": %', _ExtractNodeID, _Nodes, _RegexpCapturingGroups;
            END IF;
            INSERT INTO Edges ( ParentNodeID,                            ChildNodeID)
            VALUES            (_RegexpCapturingGroups[1]::integer, _GrandChildNodeID)
            RETURNING    EdgeID
            INTO STRICT _EdgeID;
        END IF;
        RETURN TRUE;
    END IF;

END LOOP;

RETURN TRUE;
END;
$$;
