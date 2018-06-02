CREATE OR REPLACE FUNCTION Parse(_Input text)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_TokenArray text[][];
_NodeType text;
_UnicodeCharAscii integer;
_UnicodeChar char;
_TokenString text;
_NodeID integer;
_NodePattern text;
_NodePatternUnicode text;
_SubNodeType text;
_BracketExpression text;
_BracketExpressionUnicodeChars text;
BEGIN

_TokenArray := Tokenize(_Input);

SELECT COALESCE(MAX(ASCII(UnicodeChar)), 44031)
INTO _UnicodeCharAscii
FROM NodeTypes WHERE UnicodeChar IS NOT NULL;

FOR _NodeType IN
SELECT NodeType FROM NodeTypes
WHERE UnicodeChar IS NULL
AND (NodePattern IS NOT NULL
OR NodeType = ANY((SELECT NodeType FROM Get_Token_NodeTypes()))
)
ORDER BY NodeType
LOOP
    _UnicodeCharAscii := _UnicodeCharAscii + 1;
    UPDATE NodeTypes
    SET UnicodeChar = CHR(_UnicodeCharAscii)
    WHERE NodeType = _NodeType;
END LOOP;

FOR   _NodeType, _NodePattern IN
SELECT NodeType,  NodePattern FROM NodeTypes
WHERE NodePatternUnicode IS NULL
AND NodePattern IS NOT NULL
ORDER BY NodeType
LOOP
    _NodePatternUnicode := _NodePattern;

    FOR _BracketExpression IN
    SELECT DISTINCT (regexp_matches(_NodePatternUnicode, '\[[a-zA-Z_]{2,}(?: [a-zA-Z_]{2,})*\]', 'g'))[1] ORDER BY 1
    LOOP
        _BracketExpressionUnicodeChars := '';
        FOR _SubNodeType IN
        SELECT (regexp_matches(_BracketExpression, '[a-zA-Z_]{2,}', 'g'))[1]
        LOOP
            SELECT       UnicodeChar
            INTO STRICT _UnicodeChar
            FROM NodeTypes
            WHERE NodeType = _SubNodeType
            AND UnicodeChar IS NOT NULL;
            _BracketExpressionUnicodeChars := _BracketExpressionUnicodeChars || _UnicodeChar;
        END LOOP;
        RAISE NOTICE 'NodePatternUnicode %, BracketExpression %, BracketExpressionUnicodeChars %', _NodePatternUnicode, _BracketExpression, _BracketExpressionUnicodeChars;
        _NodePatternUnicode := replace(_NodePatternUnicode, _BracketExpression, '['||_BracketExpressionUnicodeChars||']\d+');
    END LOOP;

    FOR _SubNodeType IN
    SELECT DISTINCT (regexp_matches(_NodePatternUnicode, '[a-zA-Z_]{2,}', 'g'))[1] ORDER BY 1
    LOOP
        SELECT       UnicodeChar
        INTO STRICT _UnicodeChar
        FROM NodeTypes
        WHERE NodeType = _SubNodeType
        AND UnicodeChar IS NOT NULL;
        _NodePatternUnicode := replace(_NodePatternUnicode, _SubNodeType, '(?:'||_UnicodeChar||'\d+)');
    END LOOP;

    _NodePatternUnicode := regexp_replace(_NodePatternUnicode, '\s+', '', 'g');

    UPDATE NodeTypes
    SET NodePatternUnicode = _NodePatternUnicode
    WHERE NodeType = _NodeType;

    RAISE NOTICE '%: % -> %', _NodeType, _NodePattern, _NodePatternUnicode;
END LOOP;

_NodeID := 1;
_TokenString := '';
FOR _i IN 1..array_length(_TokenArray,1) LOOP
    SELECT       UnicodeChar
    INTO STRICT _UnicodeChar
    FROM NodeTypes
    WHERE NodeType = _TokenArray[_i][1]
    AND UnicodeChar IS NOT NULL;

    _TokenString := _TokenString || _UnicodeChar || _NodeID;

    _NodeID := _NodeID + 1;
END LOOP;

RAISE NOTICE 'Token string: %', _TokenString;

RETURN TRUE;
END;
$$;
