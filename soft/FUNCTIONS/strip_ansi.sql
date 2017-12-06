CREATE OR REPLACE FUNCTION Strip_ANSI(_Text text)
RETURNS text
LANGUAGE sql
AS $$
SELECT regexp_replace($1,'\x1b\[\d+m','','g')
$$;
