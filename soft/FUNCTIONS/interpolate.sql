CREATE OR REPLACE FUNCTION Interpolate(_Text text, _ErrorInfo hstore, _Sigil char)
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
_Key   text;
_Value text;
BEGIN
FOR
    _Key,
    _Value
IN
SELECT
    COALESCE(_Sigil,'')||Key,
    Value
FROM each(_ErrorInfo)
LOOP
    IF _Key IS NULL THEN
        RAISE EXCEPTION 'NULL key in ErrorInfo %', _ErrorInfo;
    END IF;
    _Text := replace(_Text, _Key, COALESCE(_Value,'NULL'));
END LOOP;
RETURN _Text;
END;
$$;
