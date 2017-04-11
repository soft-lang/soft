CREATE OR REPLACE FUNCTION Set_Program_Node(_ProgramID integer, _GotoNodeID integer, _CurrentNodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_OK boolean;
BEGIN
RAISE NOTICE '% % %', _ProgramID, _GotoNodeID, _CurrentNodeID;
UPDATE Programs
SET NodeID = _GotoNodeID
WHERE ProgramID = _ProgramID
AND NodeID IS NOT DISTINCT FROM _CurrentNodeID
RETURNING TRUE INTO STRICT _OK;
RAISE NOTICE 'FOO';
RETURN TRUE;
END;
$$;
