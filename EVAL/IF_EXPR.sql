CREATE OR REPLACE FUNCTION "EVAL"."IF_EXPR" (boolean, anyelement, anyelement) RETURNS anyelement LANGUAGE sql AS $$ SELECT CASE $1 WHEN TRUE THEN $2 ELSE $3 END $$;
