CREATE OR REPLACE FUNCTION "EVAL"."DIVIDE"(anyelement, anyelement)
RETURNS anyelement
LANGUAGE sql
AS $$
SELECT $1 / $2
$$;
