CREATE OR REPLACE FUNCTION One_Line(_Text text)
RETURNS text
LANGUAGE sql
AS $$
SELECT regexp_replace($1, '\s+', ' ', 'sg');
$$;
