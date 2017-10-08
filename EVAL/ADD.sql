CREATE OR REPLACE FUNCTION "EVAL"."ADD"(anyelement, anyelement)
RETURNS anyelement
LANGUAGE sql
AS $$
SELECT $1 + $2
$$;

CREATE OR REPLACE FUNCTION "EVAL"."ADD"(text, text)
RETURNS text
LANGUAGE sql
AS $$
SELECT $1 || $2
$$;
