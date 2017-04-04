CREATE OR REPLACE FUNCTION "EVAL"."MULTIPLY" (anyelement, anyelement) RETURNS anyelement LANGUAGE sql AS $$ SELECT $1 * $2 $$;
