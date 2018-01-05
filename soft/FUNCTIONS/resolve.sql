CREATE OR REPLACE FUNCTION Resolve(_NodeID integer, _Name name)
RETURNS integer
LANGUAGE sql
AS $$
SELECT Find_Node(
    _NodeID                    := $1,
    _Descend                   := TRUE,
    _Strict                    := FALSE,
    _Names                     := ARRAY[$2],
    _MustBeDeclaredAfter       := (Node_Type(Child($1)) <> 'CALL'),
    _SelectLastIfMultipleMatch := TRUE,
    _Paths                     := ARRAY[
        '<- DECLARATION <- VARIABLE[1]',
        '<- PARAMETERS  <- VARIABLE[1]'
    ]
)
$$;
