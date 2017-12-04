CREATE OR REPLACE FUNCTION New_Environment(_NodeID integer)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID     integer;
_EnvironmentID integer;
BEGIN
SELECT ProgramID INTO STRICT _ProgramID FROM Nodes WHERE NodeID = _NodeID;

INSERT INTO Environments (ProgramID, EnvironmentID, ScopeNodeID)
SELECT _ProgramID, MAX(EnvironmentID)+1, _NodeID
FROM Environments
WHERE ProgramID = _ProgramID
RETURNING    EnvironmentID
INTO STRICT _EnvironmentID;

RETURN _EnvironmentID;
END;
$$;
