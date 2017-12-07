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
    _Text := replace(_Text, _Key, _Value);
END LOOP;
RETURN _Text;
END;
$$;
