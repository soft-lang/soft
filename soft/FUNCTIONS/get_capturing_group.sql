CREATE OR REPLACE FUNCTION Get_Capturing_Group(_String text, _Pattern text, _Strict boolean)
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
_RegexpCapturingGroups text[];
BEGIN
IF _Strict IS TRUE THEN
    SELECT * INTO STRICT _RegexpCapturingGroups FROM regexp_matches(_String, _Pattern, 'g');
ELSIF _Strict IS FALSE THEN
    _RegexpCapturingGroups := regexp_matches(_String, _Pattern);
ELSE
    RAISE EXCEPTION 'Undefined input param _Strict';
END IF;

_RegexpCapturingGroups := array_remove(_RegexpCapturingGroups,NULL);

IF (array_length(_RegexpCapturingGroups,1) = 1) IS NOT TRUE THEN
    RAISE EXCEPTION 'Regexp % did not return a single capturing group from "%": %', _Pattern, _String, _RegexpCapturingGroups;
END IF;

RETURN _RegexpCapturingGroups[1];
EXCEPTION WHEN OTHERS THEN
    RAISE '%: String "%" Pattern "%" Strict "%"', SQLERRM, _String, _Pattern, _Strict;
END;
$$;
