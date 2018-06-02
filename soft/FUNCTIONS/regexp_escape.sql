CREATE OR REPLACE FUNCTION RegExp_Escape(_String text)
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
_Char text;
_Escaped text;
_Esc text;
_Hex text;
BEGIN
_Escaped := '';
FOREACH _Char IN ARRAY regexp_split_to_array(_String,'') LOOP
    -- Regular Expression Character-entry Escapes:
    _Esc := '
        7 => "a",
        8 => "b",
        9 => "t",
        10 => "n",
        11 => "v",
        12 => "f",
        13 => "r",
        27 => "e",
        92 => "B"
    '::hstore->(ascii(_Char)::text);
    IF _Esc IS NOT NULL THEN
        _Escaped := _Escaped || E'\\' || _Esc;
    ELSIF ascii(_Char) BETWEEN 1 AND 31 OR ascii(_Char) = 127 THEN
        _Escaped := _Escaped || E'\\x' || to_hex(ascii(_Char));
    ELSIF _Char = E'\\' THEN
        _Escaped := _Escaped || E'\\B';
    ELSIF _Char IN ('$','(',')','*','+','.','?','[',']','^','{','|','}','-') THEN
        _Escaped := _Escaped || E'\\' || _Char;
    ELSIF ascii(_Char) BETWEEN 32 AND 126 THEN
        _Escaped := _Escaped || _Char;
    ELSE
        _Hex := to_hex(ascii(_Char));
        IF length(_Hex) <= 3 THEN
            _Escaped := _Escaped || E'\\x' || _Hex;
        ELSIF length(_Hex) = 4 THEN
            _Escaped := _Escaped || E'\\u' || _Hex;
        ELSIF length(_Hex) BETWEEN 5 AND 8 THEN
            _Escaped := _Escaped || E'\\U' || lpad(_Hex,8,'0');
        ELSE
            RAISE EXCEPTION 'Unexpected hex length for char: Char % Hex %', _Char, _Hex;
        END IF;
    END IF;
END LOOP;
RETURN _Escaped;
END;
$$;
