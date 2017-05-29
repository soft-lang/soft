CREATE OR REPLACE FUNCTION Quote(text)
RETURNS text
LANGUAGE sql
AS $BODY$
SELECT CASE WHEN $1 LIKE $$%'%$$ THEN pg_catalog.quote_literal($1) ELSE $$'$$||$1||$$'$$ END
$BODY$;
