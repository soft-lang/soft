CREATE OR REPLACE FUNCTION Set_Node_Value(_NodeID integer, _PrimitiveValue anyelement)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_OK boolean;
BEGIN
EXECUTE format($SQL$
UPDATE Nodes SET
    PrimitiveType  = %1$L::regtype,
    PrimitiveValue = %2$L::text
WHERE NodeID = %3$s
AND DeathPhaseID IS NULL
RETURNING TRUE
$SQL$,
    pg_typeof(_PrimitiveValue),
    _PrimitiveValue::text,
    _NodeID
) INTO STRICT _OK;
RETURN TRUE;
END;
$$;

CREATE OR REPLACE FUNCTION Set_Node_Value(_NodeID integer, _PrimitiveType regtype, _PrimitiveValue text)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_OK boolean;
BEGIN
EXECUTE format($SQL$
UPDATE Nodes SET
    PrimitiveType  = %1$L::regtype,
    PrimitiveValue = %2$L::%1$s
WHERE NodeID = %3$s
AND DeathPhaseID IS NULL
RETURNING TRUE
$SQL$,
    _PrimitiveType::text,
    _PrimitiveValue,
    _NodeID
) INTO STRICT _OK;
RETURN TRUE;
END;
$$;
