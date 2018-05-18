CREATE OR REPLACE FUNCTION Expand_Node_Pattern(_NodePattern text, _LanguageID integer)
RETURNS text
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
_Match text;
BEGIN

IF strpos(_NodePattern, '**') <> 0 THEN
    RAISE EXCEPTION 'Magic reserved text "**" cannot be used! LanguagID % NodePattern %', _LanguageID, _NodePattern;
END IF;

_NodePattern := replace(_NodePattern, '[A-Z_]+', '**');

FOR _Match IN
SELECT regexp_matches[1] FROM (
    SELECT regexp_matches(_NodePattern, '([A-Z_]+)','g')
) AS X
ORDER BY length(regexp_matches[1]) DESC
LOOP
    IF EXISTS (SELECT 1 FROM NodeTypes WHERE LanguageID = _LanguageID AND NodeType = _Match) THEN
        CONTINUE;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM NodeTypes WHERE LanguageID = _LanguageID AND NodeGroup = _Match) THEN
        RAISE EXCEPTION 'No NodeTypes with NodeGroup/NodeType % exists for LanguagID % NodePattern %', _Match, _LanguageID, _NodePattern;
    END IF;
    _NodePattern := replace(_NodePattern, _Match, (
        SELECT '(?:'||string_agg(NodeType,'|' ORDER BY NodeType)||')' FROM NodeTypes WHERE LanguageID = _LanguageID AND NodeGroup = _Match
    ));
END LOOP;

_NodePattern := replace(_NodePattern, '**', '<[A-Z_]+\d+>');

_NodePattern := regexp_replace(
    _NodePattern,
    '(\m(?:'||(SELECT string_agg(NodeType,'|' ORDER BY NodeType) FROM NodeTypes WHERE LanguageID = _LanguageID)||')\M)',
    '<\1\d+>',
    'g'
);

_NodePattern := regexp_replace(_NodePattern, '\s+', '', 'g');

RETURN _NodePattern;
END;
$$;


