CREATE OR REPLACE FUNCTION "EVAL"."NOT_EQUAL"(anyelement, anyelement)
RETURNS boolean
LANGUAGE sql AS $$
SELECT $1 <> $2
$$;
