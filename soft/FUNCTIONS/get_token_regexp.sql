CREATE OR REPLACE FUNCTION Get_Token_Regexp(_NodeType text)
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
_LiteralPattern text;
_SubToken text;
BEGIN
SELECT LiteralPattern
INTO  _LiteralPattern
FROM NodeTypes
WHERE NodeType = _NodeType;
IF NOT FOUND THEN
    RAISE EXCEPTION 'NodeType "%" does not exist', _NodeType;
END IF;

FOR _SubToken IN
SELECT DISTINCT (regexp_matches(_LiteralPattern, '[a-zA-Z_]{2,}', 'g'))[1]
LOOP
    _LiteralPattern := replace(_LiteralPattern, _SubToken, Get_Token_Regexp(_SubToken));
END LOOP;

RETURN regexp_replace(_LiteralPattern, '\s+', '', 'g');
END;
$$;
