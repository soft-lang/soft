CREATE OR REPLACE FUNCTION Global(_NodeID integer)
RETURNS boolean
LANGUAGE sql
AS $$
SELECT Find_Node(
    _NodeID  := $1,
    _Descend := TRUE,
    _Strict  := FALSE,
    _Paths   := ARRAY[
        '-> FUNCTION_DECLARATION',
        '-> BLOCK_STATEMENT',
        '-> IF_STATEMENT',
        '-> WHILE_STATEMENT',
        '-> FOR_STATEMENT',
        '-> CLASS_DECLARATION'
    ]
) IS NULL
$$;
