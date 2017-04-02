CREATE OR REPLACE FUNCTION Get_Source_Code_Node(_ProgramID integer)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_NodeID integer;
BEGIN
SELECT NodeID INTO STRICT _NodeID FROM Nodes WHERE ProgramID = _ProgramID ORDER BY NodeID LIMIT 1;
RETURN _NodeID;
END;
$$;
