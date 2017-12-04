CREATE OR REPLACE FUNCTION Closure(_NodeID integer)
RETURNS boolean
LANGUAGE sql
AS $$
SELECT Closure FROM Nodes WHERE NodeID = $1
$$;
