CREATE OR REPLACE FUNCTION Set_Program_Node(_NodeID integer, _Direction direction DEFAULT NULL)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_OK boolean;
BEGIN
UPDATE Programs SET
    NodeID    = _NodeID,
    Direction = COALESCE(_Direction,Direction)
WHERE ProgramID = (SELECT ProgramID FROM Nodes WHERE NodeID = _NodeID)
RETURNING TRUE INTO STRICT _OK;
RETURN TRUE;
END;
$$;
