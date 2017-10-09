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
_PrimitiveValue    text;
_Fragment         text;
BEGIN

_NodeIDs := ARRAY(
    SELECT DISTINCT Get_Parent_Nodes(_NodeID := regexp_matches[1]::integer) AS NodeID
    FROM regexp_matches($1,'(?:^| )[A-Z_]+(\d+)','g')
    ORDER BY NodeID
);

SELECT DISTINCT ProgramID INTO STRICT _ProgramID FROM Nodes WHERE NodeID = ANY(_NodeIDs);

SELECT                 NodeID,     BirthPhaseID
INTO STRICT _SourceCodeNodeID, _TokenizePhaseID
FROM Nodes
WHERE ProgramID = _ProgramID
ORDER BY NodeID
LIMIT 1;

RAISE NOTICE 'NodeIDs % ProgramID % SourceCodeNodeID % TokenizePhaseID %', _NodeIDs, _ProgramID, _SourceCodeNodeID, _TokenizePhaseID;

_Fragment := '';

FOR    _TokenNodeID, _PrimitiveValue IN
SELECT       NodeID,  PrimitiveValue
FROM Nodes
WHERE ProgramID  = _ProgramID
AND BirthPhaseID = _TokenizePhaseID
AND NodeID       > _SourceCodeNodeID
ORDER BY NodeID
LOOP
    IF _PrimitiveValue IS NULL THEN
        -- All nodes generated during the tokenize phase MUST PrimitiveValue set,
        -- since they originate from a Literal or a LiteralPattern.
        -- Only abstract nodes generated in later phases can PrimitiveValue IS NULL.
        RAISE EXCEPTION 'Unexpected PrimitiveValue NULL value at TokenNodeID %', _TokenNodeID;
    END IF;
    RAISE NOTICE 'TokenNodeID % PrimitiveValue %', _TokenNodeID, _PrimitiveValue;
    _Fragment := _Fragment || CASE WHEN _TokenNodeID = ANY(_NodeIDs) THEN Colorize(_PrimitiveValue, _Color) ELSE _PrimitiveValue END;
END LOOP;

RETURN _Fragment;
END;
$$;
