CREATE OR REPLACE FUNCTION Global(_NodeID integer)
RETURNS boolean
LANGUAGE sql
AS $$
SELECT 'PROGRAM' IN (
    Node_Type(Child(Child($1))),
    Node_Type(Child(Child(Child($1))))
)
$$;
