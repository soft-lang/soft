CREATE OR REPLACE FUNCTION "VALIDATE"."ENTER_FOR_BODY"(_NodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
BEGIN
IF Node_Type(Parent(Parent(_NodeID, 'STATEMENT'))) = 'DECLARATION' THEN
    PERFORM Error(
        _NodeID    := _NodeID,
        _ErrorType := 'EXPECT_EXPRESSION'
    );
    RETURN FALSE;
END IF;

RETURN TRUE;
END;
$$;
