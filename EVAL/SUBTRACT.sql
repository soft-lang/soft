CREATE OR REPLACE FUNCTION "EVAL"."SUBTRACT"(anyelement, anyelement)
RETURNS anyelement
LANGUAGE sql AS $$
SELECT $1 - $2
$$;
