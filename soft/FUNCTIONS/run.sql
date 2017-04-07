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
BEGIN
LOOP
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
