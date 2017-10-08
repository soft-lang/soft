CREATE OR REPLACE FUNCTION Precedence(_NodeTypeID integer)
RETURNS integer
LANGUAGE sql
AS $$
SELECT COALESCE(
    (SELECT MIN(NodeTypeID) FROM NodeTypes WHERE Precedence = (SELECT Precedence FROM NodeTypes WHERE NodeTypeID = $1)),
    $1
)
$$;
