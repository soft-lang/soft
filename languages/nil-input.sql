CREATE OR REPLACE FUNCTION "EVAL"."NOT"()        RETURNS boolean LANGUAGE sql AS $$ SELECT FALSE  $$;

CREATE OR REPLACE FUNCTION "EVAL"."NOT"(nil)        RETURNS boolean LANGUAGE sql AS $$ SELECT TRUE  $$;

CREATE OR REPLACE FUNCTION "EVAL"."EQUAL"(nil, nil)         RETURNS boolean LANGUAGE sql AS $$ SELECT TRUE    $$;
CREATE OR REPLACE FUNCTION "EVAL"."EQUAL"(nil, integer)     RETURNS boolean LANGUAGE sql AS $$ SELECT FALSE   $$;
CREATE OR REPLACE FUNCTION "EVAL"."EQUAL"(nil, text)        RETURNS boolean LANGUAGE sql AS $$ SELECT FALSE   $$;
CREATE OR REPLACE FUNCTION "EVAL"."EQUAL"(nil, numeric)     RETURNS boolean LANGUAGE sql AS $$ SELECT FALSE   $$;
CREATE OR REPLACE FUNCTION "EVAL"."EQUAL"(nil, boolean)     RETURNS boolean LANGUAGE sql AS $$ SELECT FALSE   $$;
CREATE OR REPLACE FUNCTION "EVAL"."EQUAL"(integer, nil)     RETURNS boolean LANGUAGE sql AS $$ SELECT FALSE   $$;
CREATE OR REPLACE FUNCTION "EVAL"."EQUAL"(text, nil)        RETURNS boolean LANGUAGE sql AS $$ SELECT FALSE   $$;
CREATE OR REPLACE FUNCTION "EVAL"."EQUAL"(numeric, nil)     RETURNS boolean LANGUAGE sql AS $$ SELECT FALSE   $$;
CREATE OR REPLACE FUNCTION "EVAL"."EQUAL"(boolean, nil)     RETURNS boolean LANGUAGE sql AS $$ SELECT FALSE   $$;

CREATE OR REPLACE FUNCTION "EVAL"."NOT_EQUAL"(nil, nil)         RETURNS boolean LANGUAGE sql AS $$ SELECT FALSE    $$;
CREATE OR REPLACE FUNCTION "EVAL"."NOT_EQUAL"(nil, integer)     RETURNS boolean LANGUAGE sql AS $$ SELECT TRUE     $$;
CREATE OR REPLACE FUNCTION "EVAL"."NOT_EQUAL"(nil, text)        RETURNS boolean LANGUAGE sql AS $$ SELECT TRUE     $$;
CREATE OR REPLACE FUNCTION "EVAL"."NOT_EQUAL"(nil, numeric)     RETURNS boolean LANGUAGE sql AS $$ SELECT TRUE     $$;
CREATE OR REPLACE FUNCTION "EVAL"."NOT_EQUAL"(nil, boolean)     RETURNS boolean LANGUAGE sql AS $$ SELECT TRUE     $$;
CREATE OR REPLACE FUNCTION "EVAL"."NOT_EQUAL"(integer, nil)     RETURNS boolean LANGUAGE sql AS $$ SELECT TRUE     $$;
CREATE OR REPLACE FUNCTION "EVAL"."NOT_EQUAL"(text, nil)        RETURNS boolean LANGUAGE sql AS $$ SELECT TRUE     $$;
CREATE OR REPLACE FUNCTION "EVAL"."NOT_EQUAL"(numeric, nil)     RETURNS boolean LANGUAGE sql AS $$ SELECT TRUE     $$;
CREATE OR REPLACE FUNCTION "EVAL"."NOT_EQUAL"(boolean, nil)     RETURNS boolean LANGUAGE sql AS $$ SELECT TRUE     $$;
