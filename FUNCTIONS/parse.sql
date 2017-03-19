CREATE OR REPLACE FUNCTION soft.Parse(_LanguageID integer, _Nodes text, _Output text DEFAULT NULL, _GrandChildNodeID integer DEFAULT NULL)
RETURNS boolean
LANGUAGE plpgsql
SET search_path TO soft, public, pg_temp
AS $$
DECLARE
_NodePattern           text;
_RegexpCapturingGroups text[];
_MatchedNodes          text;
_MatchedNode           text;
_ChildNodeTypeID       integer;
_ChildNodeType         text;
_ParentNodeID          integer;
_ChildNodeID           integer;
_EdgeID                integer;
_Input                 text;
_ExtractNodeID         text := '^[A-Z_]+(\d+)$';
BEGIN

LOOP
    SELECT
        NodeTypes.NodeTypeID,
        NodeTypes.NodeType,
        NodeTypes.NodePattern,
        NodeTypes.Input
    INTO
        _ChildNodeTypeID,
        _ChildNodeType,
        _NodePattern,
        _Input
    FROM NodeTypes
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

    _Nodes := regexp_replace(_Nodes, _MatchedNodes, COALESCE(_Output,_ChildNodeType)||_ChildNodeID);

    FOREACH _MatchedNode IN ARRAY regexp_split_to_array(_MatchedNodes, ' ') LOOP
        _RegexpCapturingGroups := regexp_matches(_MatchedNode, _ExtractNodeID);
        IF (array_length(_RegexpCapturingGroups,1) = 1) IS NOT TRUE THEN
            RAISE EXCEPTION 'Regexp % did not return a single capturing group from "%": %', _ExtractNodeID, _MatchedNode, _RegexpCapturingGroups;
        END IF;

        _ParentNodeID := _RegexpCapturingGroups[1]::integer;

        IF _GrandChildNodeID IS NOT NULL THEN
            DELETE FROM Edges WHERE ChildNodeID = _GrandChildNodeID AND ParentNodeID = _ParentNodeID;
        END IF;

        IF _Input IS NULL OR _MatchedNode ~ ('^'||_Input||'\d+$') THEN
            INSERT INTO Edges ( ParentNodeID,  ChildNodeID)
            VALUES            (_ParentNodeID, _ChildNodeID)
            RETURNING    EdgeID
            INTO STRICT _EdgeID;
        END IF;
    END LOOP;

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
