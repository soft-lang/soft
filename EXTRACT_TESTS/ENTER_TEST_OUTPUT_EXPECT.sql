CREATE OR REPLACE FUNCTION "EXTRACT_TESTS"."ENTER_TEST_OUTPUT_EXPECT"(_NodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
BEGIN
UPDATE Tests SET
    ExpectedSTDOUT = array_append(ExpectedSTDOUT, Primitive_Value(_NodeID))
WHERE ProgramID = (SELECT ProgramID FROM Nodes WHERE NodeID = _NodeID);
RETURN TRUE;
END;
$$;
