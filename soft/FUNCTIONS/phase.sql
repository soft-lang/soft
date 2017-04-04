CREATE OR REPLACE FUNCTION Phase(_PhaseID integer)
RETURNS text
LANGUAGE sql
AS $$
SELECT Phase::text FROM Phases WHERE PhaseID = $1
$$;
