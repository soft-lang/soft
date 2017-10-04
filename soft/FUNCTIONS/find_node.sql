CREATE OR REPLACE FUNCTION Find_Node(_NodeID integer, _Descend boolean, _Strict boolean, _Paths text[]) RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_InputNodeID     integer;
_LanguageID      integer;
_Path            text;
_Name            text;
_SQL             text;
_JOINs           text;
_WHEREs          text;
_Tokens          text[];
_Direction       text;
_NodeType        text;
_i               integer;
_j               integer;
_k               integer;
_FoundNodeID     integer;
_Count           bigint;
_WalkableNodeIDs integer[];
_EdgeNumber      integer;
BEGIN
_InputNodeID := _NodeID;
IF _InputNodeID IS NULL THEN
    RETURN NULL;
END IF;
PERFORM Log(
    _NodeID   := _InputNodeID,
    _Severity := 'DEBUG3',
    _Message  := format('Find node %s %s %s %s', _InputNodeID, _Descend, _Strict, _Paths)
);
SELECT NodeTypes.LanguageID
INTO STRICT     _LanguageID
FROM Nodes
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
WHERE Nodes.NodeID = _NodeID;
_WalkableNodeIDs := ARRAY[]::integer[];
LOOP
    _JOINs := '';
    _WHEREs := '';
    _i := 0;
    _k := 0;
    LOOP
        _i := _i + 1;
        IF _Paths[_i] IS NULL THEN
            EXIT;
        END IF;
        _Path := _Paths[_i];
        IF _Paths[_i+1] IS NOT NULL THEN
            _i    := _i + 1;
            _Name := _Paths[_i];
        ELSE
            _Name := NULL;
        END IF;
        _Tokens := regexp_split_to_array(_Path, '\s+');
        _j := 0;
        LOOP
            IF _j*2 >= array_length(_Tokens,1) THEN
                EXIT;
            END IF;
            _Direction := _Tokens[_j*2+1];
            _NodeType  := _Tokens[_j*2+2];
            IF _Direction = '<-' THEN
                _JOINs := _JOINs || format('
                    INNER JOIN Edges AS Edge%1$s ON Edge%1$s.ChildNodeID = Node%1$s.NodeID
                    INNER JOIN Nodes AS Node%2$s ON Node%2$s.NodeID      = Edge%1$s.ParentNodeID
                ', _k, _k+1);
            ELSIF _Direction = '->' THEN
                _JOINs := _JOINs || format('
                    INNER JOIN Edges AS Edge%1$s ON Edge%1$s.ParentNodeID = Node%1$s.NodeID
                    INNER JOIN Nodes AS Node%2$s ON Node%2$s.NodeID       = Edge%1$s.ChildNodeID
                ', _k, _k+1);
            ELSE
                RAISE EXCEPTION 'Invalid direction %', _Direction;
            END IF;
            IF _NodeType ~ '^\d+' THEN
                _EdgeNumber := substring(_NodeType from '^(\d+)')::integer;
                _NodeType   := regexp_replace(_NodeType, '^\d+', '');
                _WHEREs     := _WHEREs || format($SQL$
                    AND Edge%1$s.EdgeID = (
                        SELECT EdgeID FROM (
                            SELECT EdgeID, ROW_NUMBER() OVER (ORDER BY EdgeID) FROM Edges WHERE ChildNodeID = Node%1$s.NodeID AND DeathPhaseID IS NULL
                        ) AS X
                        WHERE X.ROW_NUMBER = %2$s
                    )
                $SQL$, _k, _EdgeNumber);
            END IF;
            IF _NodeType LIKE '%|%' THEN
                _WHEREs := _WHEREs || format($SQL$
                    AND Edge%1$s.DeathPhaseID IS NULL
                    AND Node%2$s.DeathPhaseID IS NULL
                    AND Node%2$s.NodeTypeID IN (SELECT NodeTypeID FROM NodeTypes WHERE LanguageID = %3$s AND NodeType IN (%4$s))
                $SQL$, _k, _k+1, _LanguageID, (
                    SELECT string_agg(quote_literal,',') FROM (SELECT quote_literal(unnest(regexp_split_to_array(_NodeType,'\|')))) AS X
                ));
            ELSE
                _WHEREs := _WHEREs || format($SQL$
                    AND Edge%1$s.DeathPhaseID IS NULL
                    AND Node%2$s.DeathPhaseID IS NULL
                    AND Node%2$s.NodeTypeID = (SELECT NodeTypeID FROM NodeTypes WHERE LanguageID = %3$s AND NodeType = %4$L)
                $SQL$, _k, _k+1, _LanguageID, _NodeType);
            END IF;
            IF _EdgeNumber IS NOT NULL THEN
            END IF;
            _j := _j + 1;
            _k := _k + 1;
        END LOOP;
        IF _Name IS NOT NULL THEN
            _WHEREs := _WHEREs || format($SQL$
                AND Node%1$s.PrimitiveType  = 'name'::regtype
                AND Node%1$s.PrimitiveValue = %2$L
            $SQL$, _k, _Name);
        END IF;
    END LOOP;
    _SQL := format($SQL$
        SELECT Node%1$s.NodeID, COUNT(*) OVER ()
        FROM Nodes AS Node0
        %2$s
        WHERE Node0.NodeID       = %3$s
        AND   Node0.DeathPhaseID IS NULL
        %4$s
    $SQL$,
        _k,
        _JOINs,
        _NodeID,
        _WHEREs
    );
    EXECUTE _SQL INTO _FoundNodeID, _Count;
    IF _Count > 1 THEN
        RAISE too_many_rows USING MESSAGE = format('query returned more than one row: NodeID %s Paths "%s" Count %s SQL "%s"', _NodeID, array_to_string(_Paths,','), _Count, _SQL);
    END IF;
    IF _FoundNodeID IS NOT NULL THEN
        PERFORM Log(
            _NodeID   := _InputNodeID,
            _Severity := 'DEBUG3',
            _Message  := format('Found node %s', Colorize(Node(_FoundNodeID)))
        );
        RETURN _FoundNodeID;
    ELSIF _Descend THEN
        SELECT ChildNodeID INTO _NodeID FROM Edges WHERE DeathPhaseID IS NULL AND ParentNodeID = _NodeID AND (ChildNodeID = ANY(_WalkableNodeIDs)) IS NOT TRUE ORDER BY EdgeID LIMIT 1;
        IF NOT FOUND THEN
            EXIT;
        END IF;
        IF _NodeID = ANY(_WalkableNodeIDs) THEN
            EXIT;
        END IF;
        _WalkableNodeIDs := _WalkableNodeIDs || _NodeID;
    ELSE
        EXIT;
    END IF;
END LOOP;
IF _Strict THEN
    RAISE EXCEPTION 'Query did not return exactly one row: NodeID % Paths "%" Count % SQL "%"', _NodeID, array_to_string(_Paths,','), _Count, _SQL;
END IF;
PERFORM Log(
    _NodeID   := _InputNodeID,
    _Severity := 'DEBUG3',
    _Message  := format('Node not found %s %s %s %s', _InputNodeID, _Descend, _Strict, _Paths)
);
RETURN NULL;
END;
$$;

CREATE OR REPLACE FUNCTION Find_Node(_NodeID integer, _Descend boolean, _Strict boolean, _Path text) RETURNS integer
LANGUAGE sql
AS $$
SELECT Find_Node($1,$2,$3,ARRAY[$4])
$$;
