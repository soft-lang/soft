CREATE OR REPLACE FUNCTION Save_DOT(_NodeID integer)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_DOT   text;
_DOTID integer;
BEGIN
SELECT string_agg(Get_DOT, E'\n')
INTO STRICT _DOT
FROM Get_DOT(_NodeID);

INSERT INTO DOTs (ProgramID, PhaseID, DOT)
SELECT
    Nodes.ProgramID,
    Programs.PhaseID,
    _DOT
FROM Nodes
INNER JOIN Programs ON Programs.ProgramID = Nodes.ProgramID
WHERE Nodes.NodeID = _NodeID
RETURNING    DOTID
INTO STRICT _DOTID;

RETURN _DOTID;
END;
$$;
