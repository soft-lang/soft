CREATE OR REPLACE FUNCTION Global(_NodeID integer)
RETURNS boolean
LANGUAGE sql
AS $$
SELECT Find_Node(
    _NodeID  := $1,
    _Descend := TRUE,
    _Strict  := FALSE,
    _Path    := '-> FUNCTION_DECLARATION'
) IS NULL
$$;
