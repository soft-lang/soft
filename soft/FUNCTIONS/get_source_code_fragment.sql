CREATE OR REPLACE FUNCTION Get_Source_Code_Fragment(_Nodes text, _Color text DEFAULT NULL)
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
_NodeIDs              integer[];
_ProgramID            integer;
_SourceCode           text;
_FirstChar            integer;
_LastChar             integer;
_SourceCodeCharacters integer[];
_NumChars             integer;
_Fragment             text;
_CodeInBetween        text;
BEGIN
_NodeIDs := ARRAY(SELECT DISTINCT Get_Parent_Nodes(_NodeID := regexp_matches[1]::integer) AS NodeID FROM regexp_matches($1,'(?:^| )[A-Z_]+(\d+)','g') ORDER BY NodeID);

SELECT DISTINCT ProgramID INTO STRICT _ProgramID FROM Nodes WHERE NodeID = ANY(_NodeIDs);

_SourceCode := Get_Source_Code(_ProgramID);

SELECT ARRAY(
    SELECT DISTINCT unnest(SourceCodeCharacters)
    FROM Nodes
    WHERE NodeID = ANY(_NodeIDs)
) INTO STRICT _SourceCodeCharacters;

_NumChars := length(_SourceCode);

_Fragment      := '';
_CodeInBetween := '';
FOR _Char IN 1.._NumChars LOOP
    IF _Char = ANY(_SourceCodeCharacters) THEN
        IF _FirstChar IS NULL THEN
            _FirstChar := _Char;
        END IF;
        _LastChar := _Char;
        _Fragment := _Fragment || _CodeInBetween || Colorize(substr(_SourceCode, _Char, 1), _Color);
        _CodeInBetween := '';
    ELSIF _FirstChar IS NULL THEN
        CONTINUE;
    ELSE
        _CodeInBetween := _CodeInBetween || substr(_SourceCode, _Char, 1);
    END IF;
END LOOP;

RETURN _Fragment;
END;
$$;
