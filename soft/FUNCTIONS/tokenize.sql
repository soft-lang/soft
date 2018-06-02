CREATE OR REPLACE FUNCTION Tokenize(_Input text)
RETURNS text[][]
LANGUAGE plpgsql
AS $$
DECLARE
_TokenizeNodeTypes text[];
_TokenizeRegExp text;
_Original text;
_Match text[];
_NumTokens integer;
_Result text[][];
BEGIN

_Original := _Input;

SELECT
    TokenizeNodeTypes,
    TokenizeRegExp
INTO STRICT
    _TokenizeNodeTypes,
    _TokenizeRegExp
FROM Get_Tokens_Regexp();

_NumTokens := cardinality(_TokenizeNodeTypes);

_Result := NULL;
LOOP
    IF _Input = '' THEN
        EXIT;
    END IF;
    _Match := regexp_match(_Input, _TokenizeRegExp);
    IF _Match IS NULL THEN
        RAISE EXCEPTION 'Failed to tokenize "%", remainder: %', _Original, _Input;
    END IF;
    FOR _i IN 1.._NumTokens LOOP
        IF _Match[_i] IS NOT NULL THEN
            _Result := _Result || ARRAY[[_TokenizeNodeTypes[_i], _Match[_i]]];
            _Input := substr(_Input, 1 + length(_Match[_i]));
        END IF;
    END LOOP;
END LOOP;

RETURN _Result;
END;
$$;
