CREATE OR REPLACE FUNCTION "EVAL"."LEAVE_PROGRAM"(_NodeID integer) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
BEGIN
PERFORM Log(
    _NodeID   := _NodeID,
    _Severity := 'DEBUG3',
    _Message  := format('Exit %s', Colorize(Node(_NodeID),'CYAN'))
);
UPDATE Programs SET NodeID = NULL WHERE ProgramID = _NodeID;
RETURN;
END;
$$;
