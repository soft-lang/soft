CREATE OR REPLACE FUNCTION "EVAL"."LESS_THAN" (anyelement, anyelement) RETURNS boolean LANGUAGE sql AS $$ SELECT $1 < $2 $$;
