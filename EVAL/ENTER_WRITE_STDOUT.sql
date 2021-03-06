CREATE OR REPLACE FUNCTION "EVAL"."ENTER_WRITE_STDOUT"(_NodeID integer)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
BEGIN
PERFORM Log(
    _NodeID   := _NodeID,
    _Severity := 'STDOUT',
    _Message  := Chr(Primitive_Value(Parent(_NodeID, 'DATA'))::integer)
);
RETURN;
END;
$$;
