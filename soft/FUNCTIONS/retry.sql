CREATE OR REPLACE FUNCTION Retry(_ProgramID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
BEGIN
UPDATE Programs SET DeathTime = NULL WHERE ProgramID = _ProgramID;
DELETE FROM Log WHERE ProgramID = _ProgramID;
PERFORM Walk_Tree(_ProgramID);
RETURN TRUE;
END;
$$;
