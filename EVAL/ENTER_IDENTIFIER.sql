CREATE OR REPLACE FUNCTION "EVAL"."ENTER_IDENTIFIER"(_NodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_Identifier text;
_LanguageID integer;
BEGIN

SELECT
    Nodes.PrimitiveValue::name,
    Languages.LanguageID
INTO STRICT
    _Identifier,
    _LanguageID
FROM Nodes
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
INNER JOIN Languages ON Languages.LanguageID = NodeTypes.LanguageID
WHERE Nodes.NodeID      = _NodeID
AND NodeTypes.NodeType  = 'IDENTIFIER'
AND Nodes.PrimitiveType = 'name'::regtype
AND Nodes.DeathPhaseID  IS NULL;

IF NOT EXISTS (
    SELECT 1
    FROM BuiltInFunctions
    WHERE LanguageID = _LanguageID
    AND   Identifier = _Identifier
) THEN
    PERFORM Error(
        _NodeID    := _NodeID,
        _ErrorType := 'UNDEFINED_VARIABLE_RUNTIME',
        _ErrorInfo := hstore(ARRAY[
            ['IdentifierName', _Identifier]
        ])
    );
    RETURN FALSE;
END IF;

RETURN TRUE;
END;
$$;
