CREATE OR REPLACE FUNCTION Set_Node_Value(_NodeID integer, _Value anyelement)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_OK boolean;
BEGIN
EXECUTE format($SQL$
UPDATE Nodes SET
    ValueType    = %1$L::regtype,
    %1$sValue    = %2$L::%1$s
WHERE NodeID = %3$s
RETURNING TRUE
$SQL$,
    pg_typeof(_Value),
    _Value::text,
    _NodeID
) INTO STRICT _OK;
RETURN TRUE;
END;
$$;
