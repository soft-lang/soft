CREATE OR REPLACE FUNCTION Expand_Token_Groups(_NodePattern text, _LanguageID integer)
RETURNS text
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
_Matches     text[];
BEGIN
IF (_NodePattern ~ '\(\?\#[A-Z_]+\)') IS NOT TRUE THEN
    RETURN _NodePattern;
END IF;
FOR _Matches IN
SELECT regexp_matches(_NodePattern, '(\(\?\#([A-Z_]+)\))','g')
LOOP
    IF NOT EXISTS (SELECT 1 FROM NodeTypes WHERE LanguageID = _LanguageID AND NodeGroup = _Matches[2]) THEN
        RAISE EXCEPTION 'No NodeTypes with NodeGroup % exists for LanguagID %', _Matches[2], _LanguageID;
    END IF;
    _NodePattern := replace(_NodePattern, _Matches[1], (
        SELECT '(?:'||string_agg(NodeType,'|' ORDER BY NodeType)||')' FROM NodeTypes WHERE LanguageID = _LanguageID AND NodeGroup = _Matches[2]
    ));
END LOOP;
RETURN _NodePattern;
END;
$$;


