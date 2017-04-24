CREATE OR REPLACE FUNCTION Run(
OUT OK     boolean,
OUT Error  text,
_ProgramID integer
)
RETURNS record
LANGUAGE plpgsql
AS $$
DECLARE
-- _Step integer;
BEGIN
-- _Step := 0;
OK := TRUE;
LOOP
    -- _Step := _Step + 1;
    -- RAISE NOTICE '%', _Step;
    -- IF (SELECT Phases.Phase FROM Programs JOIN Phases USING (PhaseID)) = 'MAP_VARIABLES' THEN
    --     EXIT;
    -- END IF;
    BEGIN
        IF NOT Walk_Tree(_ProgramID) THEN
            EXIT;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        OK    := FALSE;
        Error := SQLERRM;
        EXIT;
    END;
END LOOP;
RETURN;
END;
$$;
