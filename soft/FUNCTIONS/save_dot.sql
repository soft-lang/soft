CREATE OR REPLACE FUNCTION Save_DOT(_ProgramID integer)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_DOT   text;
_DOTID integer;
BEGIN

SELECT string_agg(Get_DOT, E'\n')
INTO STRICT _DOT
FROM Get_DOT(_ProgramID);

INSERT INTO DOTs (ProgramID, PhaseID, DOT)
SELECT
    ProgramID,
    PhaseID,
    _DOT
FROM Programs
WHERE ProgramID = _ProgramID
RETURNING    DOTID
INTO STRICT _DOTID;

RETURN _DOTID;
END;
$$;
