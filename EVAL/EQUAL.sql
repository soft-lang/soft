CREATE OR REPLACE FUNCTION "EVAL"."EQUAL"(anyelement, anyelement) RETURNS boolean LANGUAGE sql AS $$ SELECT $1 = $2 $$;
CREATE OR REPLACE FUNCTION "EVAL"."EQUAL"(nil, anyelement)        RETURNS boolean LANGUAGE sql AS $$ SELECT FALSE $$;
CREATE OR REPLACE FUNCTION "EVAL"."EQUAL"(anyelement, nil)        RETURNS boolean LANGUAGE sql AS $$ SELECT FALSE $$;
CREATE OR REPLACE FUNCTION "EVAL"."EQUAL"(nil, nil)               RETURNS boolean LANGUAGE sql AS $$ SELECT TRUE $$;
CREATE OR REPLACE FUNCTION "EVAL"."EQUAL"(node, node)             RETURNS boolean LANGUAGE sql AS $$ SELECT $1::text = $2::text $$;
CREATE OR REPLACE FUNCTION "EVAL"."EQUAL"(node, anyelement)       RETURNS boolean LANGUAGE sql AS $$ SELECT FALSE $$;
CREATE OR REPLACE FUNCTION "EVAL"."EQUAL"(anyelement, node)       RETURNS boolean LANGUAGE sql AS $$ SELECT FALSE $$;
CREATE OR REPLACE FUNCTION "EVAL"."EQUAL"(node, nil)              RETURNS boolean LANGUAGE sql AS $$ SELECT FALSE $$;
CREATE OR REPLACE FUNCTION "EVAL"."EQUAL"(nil, node)              RETURNS boolean LANGUAGE sql AS $$ SELECT FALSE $$;
