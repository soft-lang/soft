CREATE OR REPLACE FUNCTION Get_Source_Code_Fragment(_Nodes text, _Color text DEFAULT NULL)
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
_NodeIDs          integer[];
_ProgramID        integer;
_SourceCodeNodeID integer;
_TokenizePhaseID  integer;
_TokenNodeID      integer;
_TerminalValue    text;
_Fragment         text;
BEGIN
_NodeIDs := ARRAY(SELECT DISTINCT Get_Parent_Nodes(_NodeID := regexp_matches[1]::integer) AS NodeID FROM regexp_matches($1,'(?:^| )[A-Z_]+(\d+)','g') ORDER BY NodeID);

SELECT DISTINCT ProgramID INTO STRICT _ProgramID FROM Nodes WHERE NodeID = ANY(_NodeIDs);

SELECT NodeID, BirthPhaseID INTO STRICT _SourceCodeNodeID, _TokenizePhaseID FROM Nodes WHERE ProgramID = _ProgramID ORDER BY NodeID LIMIT 1;

_Fragment := '';

FOR    _TokenNodeID, _TerminalValue IN
SELECT       NodeID,  TerminalValue
FROM Nodes
WHERE ProgramID  = _ProgramID
AND BirthPhaseID = _TokenizePhaseID
AND NodeID       > _SourceCodeNodeID
ORDER BY NodeID
LOOP
    _Fragment := _Fragment || CASE WHEN _TokenNodeID = ANY(_NodeIDs) THEN Colorize(_TerminalValue, _Color) ELSE _TerminalValue END;
END LOOP;

RETURN _Fragment;
END;
$$;
