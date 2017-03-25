-- SELECT soft.Find_Node(82, '<- VARIABLE <- FUNCTION_DECLARATION <- STORE_ARGS')
-- 80
-- SELECT soft.Find_Node(80, '-> FUNCTION_DECLARATION -> VARIABLE -> FUNCTION_CALL')
-- 82

CREATE OR REPLACE FUNCTION soft.Find_Node(_NodeID integer, _Path text) RETURNS integer
SET search_path TO soft, public, pg_temp
LANGUAGE plpgsql
AS $$
DECLARE
_SQL text;
_JOINs text;
_WHEREs text;
_Tokens text[];
_Direction text;
_NodeType text;
_i integer;
_FoundNodeID integer;
BEGIN

_JOINs := '';
_WHEREs := '';

_Tokens := regexp_split_to_array(_Path, '\s+');

_i := 0;
LOOP
    IF _i*2 >= array_length(_Tokens,1) THEN
        EXIT;
    END IF;
    _Direction := _Tokens[_i*2+1];
    _NodeType  := _Tokens[_i*2+2];
    IF _Direction = '<-' THEN
        _JOINs := _JOINs || format('
            INNER JOIN Edges AS Edge%1$s ON Edge%1$s.ChildNodeID = Node%1$s.NodeID
            INNER JOIN Nodes AS Node%2$s ON Node%2$s.NodeID       = Edge%1$s.ParentNodeID
        ', _i, _i+1);
    ELSIF _Direction = '->' THEN
        _JOINs := _JOINs || format('
            INNER JOIN Edges AS Edge%1$s ON Edge%1$s.ParentNodeID = Node%1$s.NodeID
            INNER JOIN Nodes AS Node%2$s ON Node%2$s.NodeID       = Edge%1$s.ChildNodeID
        ', _i, _i+1);
    ELSE
        RAISE EXCEPTION 'Invalid direction %', _Direction;
    END IF;
    _WHEREs := _WHEREs || format($SQL$
        AND Node%1$s.NodeTypeID = (SELECT NodeTypeID FROM NodeTypes WHERE NodeType = %2$L)
    $SQL$, _i+1, _NodeType);
    _i := _i + 1;
END LOOP;

_SQL := format($SQL$
    SELECT Node%1$s.NodeID
    FROM Nodes AS Node0
    %2$s
    WHERE
    Node0.NodeID = %3$s
    %4$s
$SQL$,
    _i,
    _JOINs,
    _NodeID,
    _WHEREs
);

RAISE NOTICE 'SQL %', _SQL;

EXECUTE _SQL INTO STRICT _FoundNodeID;

RETURN _FoundNodeID;
END;
$$;
