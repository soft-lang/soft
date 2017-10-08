CREATE OR REPLACE FUNCTION Colorize(_Text text, _Color text DEFAULT NULL)
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
_ESCReset text;
_ESCBold  text;
_ESCColor text;
BEGIN
SELECT EscapeSequence INTO STRICT _ESCReset FROM ANSIEscapeCodes WHERE Name = 'RESET';
SELECT EscapeSequence INTO STRICT _ESCBold  FROM ANSIEscapeCodes WHERE Name = 'BOLD';

IF _Color IS NOT NULL THEN
    SELECT EscapeSequence INTO STRICT _ESCColor FROM ANSIEscapeCodes WHERE Name = _Color;
ELSE
    _ESCColor := '';
END IF;

RETURN _ESCBold || _ESCColor || _Text || _ESCReset;
END;
$$;


