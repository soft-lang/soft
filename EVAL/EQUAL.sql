CREATE OR REPLACE FUNCTION "EVAL"."EQUAL" (anyelement, anyelement) RETURNS boolean LANGUAGE sql AS $$ SELECT $1 = $2 $$;
