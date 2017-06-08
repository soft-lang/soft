CREATE OR REPLACE FUNCTION Primitive_Type(_NodeID integer)
RETURNS regtype
STRICT
LANGUAGE sql
AS $$
SELECT PrimitiveType FROM Nodes WHERE NodeID = Dereference($1)
$$;
