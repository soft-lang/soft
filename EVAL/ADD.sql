CREATE OR REPLACE FUNCTION "EVAL"."ADD" (anyelement, anyelement) RETURNS anyelement LANGUAGE sql AS $$ SELECT $1 + $2 $$;
