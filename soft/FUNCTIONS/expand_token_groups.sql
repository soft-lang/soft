CREATE OR REPLACE FUNCTION Expand_Token_Groups(_Language text)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_LanguageID  integer;
_NodeTypeID  integer;
_Matches     text[];
_NodePattern text;
_OK          boolean;
BEGIN

SELECT LanguageID INTO STRICT _LanguageID FROM Languages WHERE Language = _Language;

FOR    _NodeTypeID, _NodePattern IN
SELECT  NodeTypeID,  NodePattern FROM NodeTypes WHERE LanguageID = _LanguageID AND NodePattern ~ '\(\?\#[A-Z_]+\)' ORDER BY NodeTypeID FOR UPDATE
LOOP
    FOR _Matches IN
    SELECT regexp_matches(_NodePattern, '(\(\?\#([A-Z_]+)\))','g')
    LOOP
        IF NOT EXISTS (SELECT 1 FROM NodeTypes WHERE LanguageID = _LanguageID AND NodeGroup = _Matches[2]) THEN
            RAISE EXCEPTION 'No NodeTypes with NodeGroup % exists for LanguagID %', _Matches[2], _LanguageID;
        END IF;
        UPDATE NodeTypes SET NodePattern = replace(NodePattern, _Matches[1], (
            SELECT '(?:'||string_agg(NodeType,'|' ORDER BY NodeType)||')' FROM NodeTypes WHERE LanguageID = _LanguageID AND NodeGroup = _Matches[2]
        ))
        WHERE  LanguageID  = _LanguageID
        AND    NodeTypeID  = _NodeTypeID
        RETURNING TRUE INTO STRICT _OK;
    END LOOP;
END LOOP;

RETURN TRUE;
END;
$$;


