CREATE OR REPLACE FUNCTION Strip_Zeroes(numeric)
RETURNS numeric
LANGUAGE sql
AS $$
SELECT regexp_replace($1::text,'(\.[1-9]*)0+$','\1')::numeric
$$;
