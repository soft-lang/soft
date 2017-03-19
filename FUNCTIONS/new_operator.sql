CREATE OR REPLACE FUNCTION soft.New_Operator(_Language text, _Function regprocedure)
RETURNS integer
LANGUAGE plpgsql
SET search_path TO soft, public, pg_temp
AS $$
DECLARE
_OperatorID integer;
_LanguageID integer;
BEGIN
SELECT LanguageID INTO STRICT _LanguageID FROM Languages WHERE Language = _Language;
INSERT INTO Operators (LanguageID, Function) VALUES (_LanguageID, _Function) RETURNING OperatorID INTO STRICT _OperatorID;
RETURN _OperatorID;
END;
$$;
