CREATE OR REPLACE FUNCTION Run(_ProgramID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_Ret boolean;
_Step integer;
BEGIN
_Step := 0;
LOOP
    _Step := _Step + 1;
    RAISE NOTICE '%', _Step;
    -- IF (SELECT Phases.Phase FROM Programs JOIN Phases USING (PhaseID)) = 'EVAL' THEN
    --     EXIT;
    -- END IF;
    BEGIN
        IF NOT Walk_Tree(_ProgramID) THEN
            EXIT;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '%', SQLERRM;
        EXIT;
    END;
END LOOP;
RETURN TRUE;
END;
$$;

CREATE OR REPLACE FUNCTION Run(_Program text)
RETURNS record
LANGUAGE sql
AS $$
SELECT Run(ProgramID) FROM Programs WHERE Program = $1
$$;
