CREATE OR REPLACE FUNCTION Get_Capturing_Group(_Text text, _Regex text)
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
_RegexpCapturingGroups text[];
BEGIN
_RegexpCapturingGroups := regexp_matches(_Text, _Regex);
IF (array_length(_RegexpCapturingGroups,1) = 1) IS NOT TRUE THEN
    RAISE EXCEPTION 'Regexp % did not return a single capturing group from "%": %', _Regex, _Text, _RegexpCapturingGroups;
END IF;
RETURN _RegexpCapturingGroups[1];
END;
$$;
