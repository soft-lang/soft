CREATE OR REPLACE FUNCTION "EVAL"."NOT"(boolean)
RETURNS boolean
LANGUAGE sql AS $$
SELECT NOT $1
$$;

CREATE OR REPLACE FUNCTION "EVAL"."NOT"(anyelement)
RETURNS boolean
LANGUAGE sql AS $$
SELECT FALSE
$$;
