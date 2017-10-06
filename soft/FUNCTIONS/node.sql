CREATE OR REPLACE FUNCTION Node(_NodeID integer)
RETURNS text
LANGUAGE sql
AS $$
SELECT Get_Node_Label($1)
$$;
