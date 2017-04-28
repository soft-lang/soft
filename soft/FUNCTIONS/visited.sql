CREATE OR REPLACE FUNCTION Visited(_NodeID integer)
RETURNS boolean
LANGUAGE sql
AS $$
SELECT Visited FROM Nodes WHERE NodeID = $1
$$;
