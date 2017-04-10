CREATE OR REPLACE FUNCTION Set_Node_Value(_NodeID integer, _TerminalValue anyelement)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_OK boolean;
BEGIN
EXECUTE format($SQL$
UPDATE Nodes SET
    TerminalType  = %1$L::regtype,
    TerminalValue = %2$L::text
WHERE NodeID = %3$s
AND DeathPhaseID IS NULL
RETURNING TRUE
$SQL$,
    pg_typeof(_TerminalValue),
    _TerminalValue::text,
    _NodeID
) INTO STRICT _OK;
RETURN TRUE;
END;
$$;

CREATE OR REPLACE FUNCTION Set_Node_Value(_NodeID integer, _TerminalType regtype, _TerminalValue text)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_OK boolean;
BEGIN
EXECUTE format($SQL$
UPDATE Nodes SET
    TerminalType  = %1$L::regtype,
    TerminalValue = %2$L::%1$s
WHERE NodeID = %3$s
AND DeathPhaseID IS NULL
RETURNING TRUE
$SQL$,
    _TerminalType::text,
    _TerminalValue,
    _NodeID
) INTO STRICT _OK;
RETURN TRUE;
END;
$$;
