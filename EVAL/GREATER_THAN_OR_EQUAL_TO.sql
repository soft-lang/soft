CREATE OR REPLACE FUNCTION "EVAL"."GREATER_THAN_OR_EQUAL_TO"(anyelement, anyelement)
RETURNS boolean
LANGUAGE sql
AS $$
SELECT $1 >= $2
$$;
