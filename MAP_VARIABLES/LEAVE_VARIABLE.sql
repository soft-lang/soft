CREATE OR REPLACE FUNCTION "MAP_VARIABLES"."LEAVE_VARIABLE"(_NodeID integer)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
BEGIN

IF Declared(Resolve(_NodeID, Node_Name(_NodeID))) = Declared(_NodeID)
THEN
    PERFORM Error(
        _NodeID    := _NodeID,
        _ErrorType := 'REDECLARED_VARIABLE',
        _ErrorInfo := hstore(ARRAY[
            ['VariableName', Node_Name(_NodeID)::text]
        ])
    );
END IF;

PERFORM Set_Walkable(_NodeID, FALSE);
RETURN;
END;
$$;
