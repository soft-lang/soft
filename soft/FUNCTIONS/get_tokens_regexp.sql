CREATE OR REPLACE FUNCTION Get_Tokens_Regexp(
OUT TokenizeNodeTypes text[],
OUT TokenizeRegExp text
)
RETURNS RECORD
LANGUAGE plpgsql
AS $$
DECLARE
_NodeType text;
_RegExp text;
BEGIN

SELECT
    array_agg(NodeType ORDER BY NodeType),
    '^(?:(' || string_agg(RegExp, ')|(' ORDER BY NodeType) || '))'
INTO STRICT
    TokenizeNodeTypes,
    TokenizeRegExp
FROM Get_Token_NodeTypes();

RETURN;
END;
$$;
