CREATE OR REPLACE FUNCTION soft.Highlight_Code(_Text text, _Chars integer[])
RETURNS text
LANGUAGE plpgsql
SET search_path TO soft, public, pg_temp
AS $$
DECLARE
_Output text;
_Char text;
BEGIN
_Output := '';
FOR _i IN 1..length(_Text) LOOP
    _Char := substr(_Text,_i,1);
    _Output := _Output || CASE WHEN _i = ANY(_Chars) THEN E'\x1b[32m' || _Char || E'\x1b[0m' ELSE _Char END;
END LOOP;
RETURN _Output;
END;
$$;


