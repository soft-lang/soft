CREATE OR REPLACE FUNCTION Run(
OUT TerminalType  regtype,
OUT TerminalValue text,
_ProgramID        integer
)
RETURNS record
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
    -- IF _Step = 447 THEN
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
SELECT
    Nodes.TerminalType,
    Nodes.TerminalValue
INTO STRICT
    TerminalType,
    TerminalValue
FROM Programs
INNER JOIN Nodes ON Nodes.NodeID = Programs.NodeID
WHERE Programs.ProgramID = _ProgramID;
RETURN;
END;
$$;

CREATE OR REPLACE FUNCTION Run(_Program text)
RETURNS record
LANGUAGE sql
AS $$
SELECT Run(ProgramID) FROM Programs WHERE Program = $1
$$;
