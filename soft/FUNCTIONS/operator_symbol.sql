CREATE OR REPLACE FUNCTION Operator_Symbol(_NodeID integer, _NodeType text)
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
_Literal text;
BEGIN
SELECT Symbol.Literal
INTO STRICT  _Literal
FROM Nodes
INNER JOIN Programs            ON Programs.ProgramID = Nodes.ProgramID
INNER JOIN NodeTypes AS OP     ON OP.LanguageID      = Programs.LanguageID
INNER JOIN NodeTypes AS Symbol ON Symbol.LanguageID  = Programs.LanguageID
WHERE Nodes.NodeID   = _NodeID
AND   OP.NodeType    = _NodeType
AND   OP.NodePattern ~ ('(\m(?:'||Symbol.NodeType||')\M)')
AND   Symbol.Literal IS NOT NULL;

RETURN _Literal;
END;
$$;
