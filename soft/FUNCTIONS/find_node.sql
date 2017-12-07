CREATE OR REPLACE FUNCTION Find_Node(_NodeID integer, _Descend boolean, _Strict boolean, _Path text DEFAULT NULL, _Paths text[] DEFAULT NULL, _Names name[] DEFAULT NULL, _MustBeDeclaredAfter boolean DEFAULT FALSE, _SelectLastIfMultipleMatch boolean DEFAULT FALSE, _ErrorType text DEFAULT NULL)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_InputNodeID                  integer;
_LanguageID                   integer;
_Name                         name;
_SQL                          text;
_JOINs                        text;
_WHEREs                       text;
_Tokens                       text[];
_Direction                    text;
_NodeType                     text;
_PathIndex                    integer;
_NodeIndex                    integer;
_FoundNodeID                  integer;
_Count                        bigint;
_WalkableNodeIDs              integer[];
_EdgeNumber                   integer;
_EdgeNode                     text;
_NameIndex                    integer;
_DescendedViaEdgeID           integer;
_SQLMustBeDeclaredAfter       text;
_SQLSelectLastIfMultipleMatch text;
BEGIN
IF _Path IS NOT NULL AND _Paths IS NULL THEN
    _Paths := ARRAY[_Path];
END IF;
_InputNodeID := _NodeID;
IF _InputNodeID IS NULL THEN
    RETURN NULL;
END IF;
PERFORM Log(
    _NodeID   := _InputNodeID,
    _Severity := 'DEBUG3',
    _Message  := format('Find node %s %s %s %s %s', _InputNodeID, _Descend, _Strict, _Paths, _Names)
);
SELECT NodeTypes.LanguageID
INTO STRICT     _LanguageID
FROM Nodes
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
WHERE Nodes.NodeID = _NodeID;
_WalkableNodeIDs := ARRAY[]::integer[];
LOOP
    _PathIndex := 0;
    LOOP
        _PathIndex := _PathIndex + 1;
        IF _Paths[_PathIndex] IS NULL THEN
            EXIT;
        END IF;
        _Path := _Paths[_PathIndex];
        _Tokens := regexp_split_to_array(_Path, '\s+');
        _NodeIndex := 0;
        _JOINs := '';
        _WHEREs := '';
        LOOP
            IF _NodeIndex*2 >= array_length(_Tokens,1) THEN
                EXIT;
            END IF;
            _Direction := _Tokens[_NodeIndex*2+1];
            _NodeType  := _Tokens[_NodeIndex*2+2];
            _Name      := NULL;
            IF _NodeType ~ '\[\d+\]$' THEN
                _NameIndex := substring(_NodeType from '\[(\d+)\]$')::integer;
                _NodeType  := regexp_replace(_NodeType, '\[\d+\]$', '');
                _Name := _Names[_NameIndex];
                IF _Name IS NULL THEN
                    RAISE EXCEPTION 'Names[%] not defined, Names: %', _NameIndex, _Names;
                END IF;
            END IF;
            IF _Direction ~ '^(<-\d*|\d*<-)$' THEN
                _JOINs := _JOINs || format('
                    INNER JOIN Edges AS Edge%1$s ON Edge%1$s.ChildNodeID = Node%1$s.NodeID
                    INNER JOIN Nodes AS Node%2$s ON Node%2$s.NodeID      = Edge%1$s.ParentNodeID
                ', _NodeIndex, _NodeIndex+1);
            ELSIF _Direction ~ '^(\d*->|->\d*)$' THEN
                _JOINs := _JOINs || format('
                    INNER JOIN Edges AS Edge%1$s ON Edge%1$s.ParentNodeID = Node%1$s.NodeID
                    INNER JOIN Nodes AS Node%2$s ON Node%2$s.NodeID       = Edge%1$s.ChildNodeID
                ', _NodeIndex, _NodeIndex+1);
            ELSE
                RAISE EXCEPTION 'Invalid direction %', _Direction;
            END IF;
            IF _Direction ~ '^\d+' THEN
                _EdgeNumber := substring(_Direction from '^(\d+)')::integer;
                IF _Direction ~ '^(<-\d+|\d+->)$' THEN
                    _EdgeNode := 'ParentNodeID';
                ELSIF _Direction ~ '^(\d+<-|->\d+)$' THEN
                    _EdgeNode := 'ChildNodeID';
                ELSE
                    RAISE EXCEPTION 'Invalid direction %', _Direction;
                END IF;
                _WHEREs     := _WHEREs || format($SQL$
                    AND Edge%1$s.EdgeID = (
                        SELECT EdgeID FROM (
                            SELECT EdgeID, ROW_NUMBER() OVER (ORDER BY EdgeID) FROM Edges WHERE %2$s = Edge%1$s.%2$s AND DeathPhaseID IS NULL
                        ) AS X
                        WHERE X.ROW_NUMBER = %3$s
                    )
                $SQL$, _NodeIndex, _EdgeNode, _EdgeNumber);
            END IF;
            _WHEREs := _WHEREs || format($SQL$
                AND Edge%1$s.DeathPhaseID IS NULL
                AND Node%2$s.DeathPhaseID IS NULL
                AND Node%2$s.NodeTypeID = (SELECT NodeTypeID FROM NodeTypes WHERE LanguageID = %3$s AND NodeType = %4$L)
            $SQL$, _NodeIndex, _NodeIndex+1, _LanguageID, _NodeType);
            _NodeIndex := _NodeIndex + 1;
        END LOOP;
        IF _Name IS NOT NULL THEN
            _WHEREs := _WHEREs || format($SQL$
                AND Node%1$s.NodeName = %2$L
            $SQL$, _NodeIndex, _Name);
        END IF;

        IF  _MustBeDeclaredAfter IS TRUE
        AND _DescendedViaEdgeID  IS NOT NULL
        THEN
            _SQLMustBeDeclaredAfter := format($SQL$
                AND Edge0.EdgeID < %1$s
            $SQL$, _DescendedViaEdgeID);
        END IF;

        IF _SelectLastIfMultipleMatch IS TRUE
        THEN
            _SQLSelectLastIfMultipleMatch := format($SQL$
                ORDER BY Edge0.EdgeID DESC
                LIMIT 1
            $SQL$, _DescendedViaEdgeID);
        END IF;

        _SQL := format($SQL$
            SELECT NodeID, COUNT(*) OVER () FROM (
                SELECT Node%1$s.NodeID
                FROM Nodes AS Node0
                %2$s
                WHERE Node0.NodeID       = %3$s
                AND   Node0.DeathPhaseID IS NULL
                %4$s
                %5$s
                %6$s
            ) AS X
        $SQL$,
            _NodeIndex,
            _JOINs,
            _NodeID,
            _WHEREs,
            _SQLMustBeDeclaredAfter,
            _SQLSelectLastIfMultipleMatch
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
        END IF;
    END LOOP;
    IF _Descend THEN
        SELECT
            ChildNodeID,
            EdgeID
        INTO
            _NodeID,
            _DescendedViaEdgeID
        FROM Edges
        WHERE DeathPhaseID IS NULL
        AND ParentNodeID = _NodeID
        AND (ChildNodeID = ANY(_WalkableNodeIDs)) IS NOT TRUE
        ORDER BY EdgeID
        LIMIT 1;
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
    IF _ErrorType IS NOT NULL THEN
        PERFORM Error(
            _NodeID    := _InputNodeID,
            _ErrorType := _ErrorType
        );
        RETURN NULL;
    ELSE
        RAISE EXCEPTION 'Query did not return exactly one row: NodeID % Paths "%" SQL "%"', _NodeID, array_to_string(_Paths,','), _SQL;
    END IF;
END IF;
PERFORM Log(
    _NodeID   := _InputNodeID,
    _Severity := 'DEBUG3',
    _Message  := format('Node not found %s %s %s %s', _InputNodeID, _Descend, _Strict, _Paths)
);
RETURN NULL;
END;
$$;
