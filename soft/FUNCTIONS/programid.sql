CREATE OR REPLACE FUNCTION ProgramID(_NodeID integer)
RETURNS integer
LANGUAGE sql
AS $$
SELECT ProgramID FROM Nodes WHERE NodeID = $1
$$;
