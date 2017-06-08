CREATE OR REPLACE FUNCTION Dereference(_NodeID integer)
RETURNS integer
STRICT
LANGUAGE sql
AS $$
SELECT COALESCE(Dereference(ReferenceNodeID), NodeID) FROM Nodes WHERE NodeID = $1
$$;
