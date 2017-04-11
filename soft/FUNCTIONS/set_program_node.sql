CREATE OR REPLACE FUNCTION Set_Program_Node(_ProgramID integer, _GotoNodeID integer, _CurrentNodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_OK boolean;
BEGIN

PERFORM Log(
    _NodeID   := _GotoNodeID,
    _Severity := 'DEBUG3',
    _Message  := format('Setting program node to %s', Node(_GotoNodeID))
);

UPDATE Programs
SET NodeID = _GotoNodeID
WHERE ProgramID = _ProgramID
AND NodeID IS NOT DISTINCT FROM _CurrentNodeID
RETURNING TRUE INTO STRICT _OK;
RETURN TRUE;
END;
$$;
