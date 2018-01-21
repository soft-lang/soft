CREATE OR REPLACE FUNCTION "EVAL"."ENTER_DEC_DATA"(_NodeID integer)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_DataNodeID integer;
_OK         boolean;
BEGIN

_DataNodeID := Heap_Integer_Array(_NodeID);

UPDATE Nodes SET PrimitiveValue = (PrimitiveValue::integer - 1)::text WHERE NodeID = Dereference(_DataNodeID) RETURNING TRUE INTO STRICT _OK;

RETURN;
END;
$$;
