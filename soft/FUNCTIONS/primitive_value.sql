CREATE OR REPLACE FUNCTION Primitive_Value(_NodeID integer)
RETURNS text
STRICT
LANGUAGE sql
AS $$
SELECT PrimitiveValue FROM Nodes WHERE NodeID = Dereference($1)
$$;
