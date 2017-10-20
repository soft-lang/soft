CREATE OR REPLACE FUNCTION Truthy(_NodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_Condition boolean;
BEGIN

IF Primitive_Type(_NodeID) = 'boolean'::regtype THEN
    _Condition := Primitive_Value(_NodeID)::boolean;
ELSIF (Language(_NodeID)).TruthyNonBooleans THEN
    IF Primitive_Type(_NodeID) = 'nil'::regtype THEN
        _Condition := FALSE;
    ELSE
        _Condition := TRUE;
    END IF;
ELSE
    RAISE EXCEPTION 'NodeID % not a boolean value but of type "%"', _NodeID, Primitive_Type(_NodeID);
END IF;

RETURN _Condition;
END;
$$;
