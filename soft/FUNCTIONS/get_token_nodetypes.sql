CREATE OR REPLACE FUNCTION Get_Token_NodeTypes() RETURNS TABLE (
NodeType text,
RegExp text
)
LANGUAGE sql
AS $$
SELECT
    NodeType,
    Get_Token_Regexp(NodeType)
FROM NodeTypes
WHERE LiteralPattern IS NOT NULL
AND NodeType IN (
    SELECT DISTINCT (regexp_matches(NodePattern,'[a-zA-Z_]{2,}','g'))[1]
    FROM NodeTypes
    WHERE NodePattern IS NOT NULL
)
ORDER BY NodeType
$$;
