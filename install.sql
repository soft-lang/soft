ROLLBACK;
\set AUTOCOMMIT OFF
BEGIN;
DROP SCHEMA soft CASCADE;
COMMIT;
BEGIN;
\ir FUNCTIONS/opr_isnotdistinctfrom.sql
COMMIT;
BEGIN;
\ir OPERATORS/opr_isnotdistinctfrom.sql
COMMIT;
BEGIN;
\ir soft.sql
COMMIT;
