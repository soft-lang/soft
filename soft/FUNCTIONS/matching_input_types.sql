CREATE OR REPLACE FUNCTION Matching_Input_Types(_InputArgTypes regtype[], _ParentValueTypes regtype[])
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_NumArgs integer;
_ReturnType regtype;
_WildcardType regtype;
BEGIN

IF _InputArgTypes = _ParentValueTypes THEN
	RETURN TRUE;
END IF;

_NumArgs := array_length(_InputArgTypes,1);

IF _NumArgs IS DISTINCT FROM array_length(_ParentValueTypes,1) THEN
	RETURN FALSE;
END IF;

IF _NumArgs = 0 THEN
	RETURN TRUE;
END IF;

FOR _i IN 1.._NumArgs LOOP
	IF _InputArgTypes[_i] = _ParentValueTypes[_i] THEN
		CONTINUE;
	ELSIF _InputArgTypes[_i] = 'anyelement'::regtype
	AND _ParentValueTypes[_i] = _WildcardType
	THEN
		CONTINUE;
	ELSIF _InputArgTypes[_i] = 'anyelement'::regtype
	AND _WildcardType IS NULL
	THEN
		_WildcardType := _ParentValueTypes[_i];
	ELSE
		RETURN FALSE;
	END IF;
END LOOP;

RETURN TRUE;

END;
$$;
