CREATE OR REPLACE FUNCTION soft.Eval_Node(_NodeID integer)
RETURNS boolean
LANGUAGE plpgsql
SET search_path TO soft, public, pg_temp
AS $$
DECLARE
_FunctionName name;
_ReturnType regtype;
_SQL text;
_NameValue text;
_TextValue text;
_IntegerValue integer;
_NumericValue numeric;
_BooleanValue boolean;
_OK boolean;
_ParentValueTypes regtype[];
_ArgTypes oidvector;
_InputArgTypes regtype[];
_Count integer;
BEGIN

SELECT
    pg_proc.proname,
    pg_proc.proargtypes,
    pg_proc.prorettype::regtype
INTO
    _FunctionName,
    _ArgTypes,
    _ReturnType
FROM Nodes
INNER JOIN NodeTypes    ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
INNER JOIN pg_proc      ON pg_proc.proname      = NodeTypes.NodeType
INNER JOIN pg_namespace ON pg_namespace.oid = pg_proc.pronamespace
WHERE pg_namespace.nspname = 'soft'
AND   Nodes.NodeID         = _NodeID;
IF NOT FOUND THEN
    RAISE NOTICE 'No function found for NodeID %', _NodeID;
    RETURN FALSE;
END IF;

SELECT array_agg(pg_type.typname::regtype ORDER BY TypeOIDs.Ordinality)
INTO STRICT _InputArgTypes
FROM (
    SELECT * FROM unnest(_ArgTypes) WITH ORDINALITY AS TypeOID
) AS TypeOIDs
INNER JOIN pg_type ON pg_type.oid = TypeOIDs.TypeOID;

RAISE NOTICE 'ReturnType % InputArgTypes %', _ReturnType, _InputArgTypes;

SELECT
    format('SELECT soft.%I(%s)', _FunctionName, string_agg(COALESCE(
        quote_literal(Nodes.NameValue)||'::name',
        quote_literal(Nodes.TextValue)||'::text',
        Nodes.NumericValue::text||'::numeric',
        Nodes.IntegerValue::text||'::integer',
        Nodes.BooleanValue::text||'::boolean'
    ),',' ORDER BY Edges.EdgeID)),
    array_agg(COALESCE(Nodes.ValueType,NodeTypes.ValueType) ORDER BY Edges.EdgeID)
INTO STRICT
    _SQL,
    _ParentValueTypes
FROM Edges
INNER JOIN Nodes     ON Nodes.NodeID         = Edges.ParentNodeID
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
WHERE Edges.ChildNodeID = _NodeID;

RAISE NOTICE 'SQL % ParentValueTypes %', _SQL, _ParentValueTypes;

IF _ReturnType = 'anyelement'::regtype THEN
    SELECT (array_agg(unnest))[1]
    INTO _ReturnType
    FROM (
        SELECT unnest(_ParentValueTypes)
        EXCEPT
        SELECT unnest(_InputArgTypes)
    ) AS InferredType
    HAVING COUNT(*) = 1;
    RAISE NOTICE 'Derived1 ReturnType % from ParentValueTypes % InputArgTypes %', _ReturnType, _ParentValueTypes, _InputArgTypes;
    IF NOT FOUND THEN
        SELECT DISTINCT unnest INTO STRICT _ReturnType
        FROM (
            SELECT * FROM unnest(_InputArgTypes)
        ) AS X WHERE unnest <> 'anyelement';
        RAISE NOTICE 'Derived2 ReturnType % from ParentValueTypes % InputArgTypes %', _ReturnType, _ParentValueTypes, _InputArgTypes;
    END IF;
END IF;

IF _ReturnType = 'name'::regtype THEN
    EXECUTE _SQL INTO STRICT _NameValue;
    UPDATE Nodes SET NameValue = _NameValue, ValueType = _ReturnType WHERE NodeID = _NodeID RETURNING TRUE INTO STRICT _OK;
ELSIF _ReturnType = 'text'::regtype THEN
    EXECUTE _SQL INTO STRICT _TextValue;
    UPDATE Nodes SET TextValue = _TextValue, ValueType = _ReturnType WHERE NodeID = _NodeID RETURNING TRUE INTO STRICT _OK;
ELSIF _ReturnType = 'numeric'::regtype THEN
    EXECUTE _SQL INTO STRICT _NumericValue;
    UPDATE Nodes SET NumericValue = _NumericValue, ValueType = _ReturnType WHERE NodeID = _NodeID RETURNING TRUE INTO STRICT _OK;
ELSIF _ReturnType = 'integer'::regtype THEN
    EXECUTE _SQL INTO STRICT _IntegerValue;
    UPDATE Nodes SET IntegerValue = _IntegerValue, ValueType = _ReturnType WHERE NodeID = _NodeID RETURNING TRUE INTO STRICT _OK;
ELSIF _ReturnType = 'boolean'::regtype THEN
    EXECUTE _SQL INTO STRICT _BooleanValue;
    UPDATE Nodes SET BooleanValue = _BooleanValue, ValueType = _ReturnType WHERE NodeID = _NodeID RETURNING TRUE INTO STRICT _OK;
ELSIF _ReturnType = 'void'::regtype THEN
    EXECUTE _SQL;
ELSE
    RAISE NOTICE 'Unsupported type % % %', _FunctionName, _ReturnType, _ParentValueTypes;
END IF;

RAISE NOTICE 'Computed NodeID %, ReturnType % Value %', _NodeID, _ReturnType, COALESCE(_TextValue,_NameValue::text,_NumericValue::text,_IntegerValue::text,_BooleanValue::text);

RETURN TRUE;
END;
$$;
