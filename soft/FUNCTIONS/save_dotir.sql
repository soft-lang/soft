CREATE OR REPLACE FUNCTION Save_DOTIR(_NodeID integer)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_DOTIR   text;
_DOTIRID integer;
BEGIN
SELECT string_agg(Get_DOTIR, E'\n')
INTO STRICT _DOTIR
FROM Get_DOTIR(_NodeID);

INSERT INTO DOTIR (ProgramID, PhaseID, Direction, NodeID, DOTIR)
SELECT
    Nodes.ProgramID,
    Programs.PhaseID,
    Programs.Direction,
    Programs.NodeID,
    _DOTIR
FROM Nodes
INNER JOIN Programs ON Programs.ProgramID = Nodes.ProgramID
WHERE Nodes.NodeID = _NodeID
RETURNING    DOTIRID
INTO STRICT _DOTIRID;

RETURN _DOTIRID;
END;
$$;
