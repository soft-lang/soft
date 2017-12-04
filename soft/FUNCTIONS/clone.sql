CREATE OR REPLACE FUNCTION Clone(_NodeID integer, _EnvironmentID integer DEFAULT NULL)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_ClonedNodeID  integer;
BEGIN
IF _EnvironmentID IS NULL THEN
    _EnvironmentID := New_Environment(_NodeID);
END IF;
_ClonedNodeID := Clone_Node(_NodeID := Dereference(_NodeID), _SelfRef := FALSE, _EnvironmentID := _EnvironmentID);
RETURN _ClonedNodeID;
END;
$$;
