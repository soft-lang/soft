CREATE OR REPLACE FUNCTION Export_Node_Types(_Language text)
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
_SQL text;
_OK boolean;
BEGIN

SELECT string_agg(
'SELECT New_Node_Type(_Language := ' ||  quote(_Language)
|| COALESCE(', _NodeGroup := ' || NodeGroup, '')
|| ', _NodeType := ' ||  quote(NodeType)
|| COALESCE(', _NodePattern := '    ||  quote(NodePattern), '')
|| COALESCE(', _PrimitiveType := '   ||  quote(PrimitiveType::text), '')
|| COALESCE(', _Literal := '        ||  quote(Literal), '')
|| COALESCE(', _LiteralPattern := ' ||  quote(LiteralPattern), '')
|| COALESCE(', _Prologue := '       ||  quote((SELECT P.NodeType  FROM NodeTypes AS P  WHERE P.NodeTypeID  = NodeTypes.PrologueNodeTypeID)), '')
|| COALESCE(', _Epilogue := '       ||  quote((SELECT E.NodeType  FROM NodeTypes AS E  WHERE E.NodeTypeID  = NodeTypes.EpilogueNodeTypeID)), '')
|| COALESCE(', _GrowFrom := '       ||  quote((SELECT GF.NodeType FROM NodeTypes AS GF WHERE GF.NodeTypeID = NodeTypes.GrowFromNodeTypeID)), '')
|| COALESCE(', _GrowInto := '       ||  quote((SELECT GI.NodeType FROM NodeTypes AS GI WHERE GI.NodeTypeID = NodeTypes.GrowIntoNodeTypeID)), '')
|| COALESCE(', _NodeSeverity := '   ||  quote(NodeSeverity::text), '')
|| ');', E'\n'
ORDER BY NodeTypeID)
INTO _SQL
FROM NodeTypes
WHERE LanguageID = (SELECT LanguageID FROM Languages WHERE Language = _Language);

RETURN _SQL;
END;
$$;


