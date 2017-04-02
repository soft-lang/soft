CREATE OR REPLACE FUNCTION Get_Source_Code(_ProgramID integer)
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
_SourceCode text;
BEGIN
SELECT TerminalValue INTO STRICT _SourceCode FROM Nodes WHERE ProgramID = _ProgramID ORDER BY NodeID LIMIT 1;
RETURN _SourceCode;
END;
$$;


