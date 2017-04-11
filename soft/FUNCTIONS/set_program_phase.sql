CREATE OR REPLACE FUNCTION Set_Program_Phase(_ProgramID integer, _GotoPhaseID integer, _CurrentPhaseID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_OK boolean;
BEGIN
UPDATE Programs
SET PhaseID = _GotoPhaseID
WHERE ProgramID = _ProgramID
AND   PhaseID   = _CurrentPhaseID
RETURNING TRUE INTO STRICT _OK;
RETURN TRUE;
END;
$$;
