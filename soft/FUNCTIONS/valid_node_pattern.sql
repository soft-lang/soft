CREATE OR REPLACE FUNCTION Valid_Node_Pattern(_Language text, _NodePattern text)
RETURNS boolean
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
_LanguageID   integer;
_NodeType     text;
_NodeGroups   text;
_PatternChars text;
BEGIN

SELECT LanguageID INTO STRICT _LanguageID FROM Languages WHERE Language = _Language;

_PatternChars := _NodePattern;

_PatternChars := replace(_PatternChars, '[A-Z_]+', '');

SELECT string_agg(DISTINCT NodeGroup,'|' ORDER BY NodeGroup)
INTO _NodeGroups
FROM NodeTypes
WHERE LanguageID = _LanguageID
AND NodeGroup IS NOT NULL;
IF _NodeGroups IS NOT NULL THEN
    _PatternChars := regexp_replace(
        _PatternChars,
        '(\(\?\#(?:'||_NodeGroups||')\))',
        '',
        'g'
    );
END IF;

FOR _NodeType IN
SELECT NodeType FROM NodeTypes ORDER BY length(NodeType) DESC, NodeType
LOOP
    _PatternChars := regexp_replace(
        _PatternChars,
        '(\m(?:'||_NodeType||')\M)',
        '',
        'g'
    );
END LOOP;

IF (_PatternChars ~ '^[()?:^$|!=* ]+$') IS NOT TRUE THEN
    RAISE EXCEPTION 'Invalid node pattern "%" for language "%", remaining chars: "%"', _NodePattern, _Language, _PatternChars;
END IF;

RETURN TRUE;
END;
$$;
