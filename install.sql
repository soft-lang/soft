ROLLBACK;
\set AUTOCOMMIT ON
DROP SCHEMA soft CASCADE;
DROP SCHEMA "TOKENIZE" CASCADE;
DROP SCHEMA "PARSE" CASCADE;
\ir public/FUNCTIONS/is_not_distinct_from.sql
\ir public/OPERATORS/is_not_distinct_from.sql
\set AUTOCOMMIT OFF
BEGIN;
\ir soft.sql
COMMIT;
