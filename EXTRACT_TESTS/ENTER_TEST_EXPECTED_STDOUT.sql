CREATE OR REPLACE FUNCTION "EXTRACT_TESTS"."ENTER_TEST_EXPECTED_STDOUT"(_NodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID      integer;
_Comment        text;
_ExpectedSTDOUT text;
_ExpectedError  text;
BEGIN
SELECT       ProgramID
INTO STRICT _ProgramID
FROM Nodes WHERE NodeID = _NodeID;

_Comment := Primitive_Value(_NodeID);

_ExpectedSTDOUT := substring(_Comment from '// expect: ?(.*)');
_ExpectedError  := substring(_Comment from $RE$// (?:(?:\[(?:(?:java|c) )?line \d+\] )?Error(?: at (?:'[^']+'|end))?: |expect runtime error: )(.*)$RE$);

IF _ExpectedSTDOUT IS NOT NULL THEN
    UPDATE Tests
    SET ExpectedSTDOUT = array_append(ExpectedSTDOUT, _ExpectedSTDOUT)
    WHERE ProgramID = _ProgramID;
ELSIF _ExpectedError IS NOT NULL THEN
    UPDATE Tests
    SET ExpectedError = array_append(ExpectedError, _ExpectedError)
    WHERE ProgramID = _ProgramID;
END IF;

RETURN TRUE;
END;
$$;
