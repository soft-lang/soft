CREATE OR REPLACE FUNCTION "EVAL"."NOT_EQUAL"(anyelement, anyelement) RETURNS boolean LANGUAGE sql AS $$ SELECT $1 <> $2 $$;
CREATE OR REPLACE FUNCTION "EVAL"."NOT_EQUAL"(nil, anyelement)        RETURNS boolean LANGUAGE sql AS $$ SELECT TRUE $$;
CREATE OR REPLACE FUNCTION "EVAL"."NOT_EQUAL"(anyelement, nil)        RETURNS boolean LANGUAGE sql AS $$ SELECT TRUE $$;
CREATE OR REPLACE FUNCTION "EVAL"."NOT_EQUAL"(nil, nil)               RETURNS boolean LANGUAGE sql AS $$ SELECT FALSE $$;
CREATE OR REPLACE FUNCTION "EVAL"."NOT_EQUAL"(node, node)             RETURNS boolean LANGUAGE sql AS $$ SELECT $1::text <> $2::text $$;
