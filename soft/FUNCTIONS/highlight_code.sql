CREATE OR REPLACE FUNCTION Highlight_Code(_Text text, _SourceCodeCharacters integer[], _Color text DEFAULT NULL)
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
_Line   text;
_LineNo integer;
_Output text;
_Char   text;
BEGIN
_Output := '';
_Line   := '';
_LineNo := 1;
_Text := _Text || chr(10);
FOR _i IN 1..length(_Text) LOOP
    _Char := substr(_Text,_i,1);
    _Line := _Line || CASE WHEN _i = ANY(_SourceCodeCharacters) THEN Colorize(_Char, _Color) ELSE _Char END;
    IF _Char = chr(10) THEN
        _Output := _Output || format('%s: %s',_LineNo, _Line);
        _LineNo := _LineNo + 1;
        _Line := '';
    END IF;
END LOOP;
RETURN _Output;
END;
$$;
