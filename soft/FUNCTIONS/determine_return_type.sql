CREATE OR REPLACE FUNCTION Determine_Return_Type(_InputArgTypes regtype[], _ParentValueTypes regtype[])
RETURNS regtype
LANGUAGE plpgsql
AS $$
DECLARE
_ReturnType regtype;
BEGIN

SELECT (array_agg(unnest))[1]
INTO _ReturnType
FROM (
    SELECT unnest(_ParentValueTypes)
    EXCEPT
    SELECT unnest(_InputArgTypes)
) AS InferredType
HAVING COUNT(*) = 1;
IF NOT FOUND THEN
    SELECT DISTINCT unnest INTO STRICT _ReturnType
    FROM (
        SELECT * FROM unnest(_InputArgTypes)
    ) AS X WHERE unnest <> 'anyelement'::regtype;
END IF;

RETURN _ReturnType;
END;
$$;
