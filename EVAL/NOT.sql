CREATE OR REPLACE FUNCTION "EVAL"."NOT" (boolean) RETURNS boolean LANGUAGE sql AS $$ SELECT NOT $1 $$;