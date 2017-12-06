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
    IF strpos(_Text, UPPER(_Key)) > 0 THEN
        _Text := replace(_Text, UPPER(_Key), UPPER(_Value));
    ELSIF strpos(_Text, lower(_Key)) > 0 THEN
        _Text := replace(_Text, lower(_Key), lower(_Value));
    ELSE
        _Text := replace(_Text, _Key, _Value);
    END IF;
END LOOP;
RETURN _Text;
END;
$$;
