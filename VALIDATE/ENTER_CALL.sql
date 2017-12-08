CREATE OR REPLACE FUNCTION "VALIDATE"."ENTER_CALL"(_NodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_NumArguments  integer;
_MaxParameters integer;
BEGIN

_NumArguments := array_length(Call_Args(_NodeID),1);
_MaxParameters := (Language(_NodeID)).MaxParameters;

IF _NumArguments > _MaxParameters THEN
    PERFORM Error(
        _NodeID := _NodeID,
        _ErrorType := 'TOO_MANY_ARGUMENTS',
        _ErrorInfo := hstore(ARRAY[
            ['NumArguments',  _NumArguments::text],
            ['MaxParameters', _MaxParameters::text]
        ])
    );
    RETURN FALSE;
END IF;

RETURN TRUE;
END;
$$;
