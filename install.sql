ROLLBACK;
\set AUTOCOMMIT OFF
BEGIN;
DROP SCHEMA soft CASCADE;
COMMIT;
BEGIN;
\ir soft.sql
COMMIT;
