CREATE OR REPLACE FUNCTION Save_DOTIR(_NodeID integer)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID  integer;
_DOTIR      text;
_DOTIRID    integer;
_PrevNodeID integer;
BEGIN

SELECT ProgramID INTO STRICT _ProgramID FROM Nodes WHERE NodeID = _NodeID;

SELECT NodeID INTO _PrevNodeID FROM DOTIR WHERE ProgramID = _ProgramID ORDER BY DOTIRID DESC LIMIT 1;

SELECT string_agg(Get_DOTIR, E'\n')
INTO STRICT _DOTIR
FROM Get_DOTIR(_NodeID, _PrevNodeID);

IF _DOTIR IS NULL THEN
    RETURN NULL;
END IF;

INSERT INTO DOTIR (ProgramID, PhaseID, Direction, NodeID, DOTIR)
SELECT
    _ProgramID,
    PhaseID,
    Direction,
    NodeID,
    _DOTIR
FROM Programs
WHERE ProgramID = _ProgramID
RETURNING    DOTIRID
INTO STRICT _DOTIRID;

RETURN _DOTIRID;
END;
$$;
