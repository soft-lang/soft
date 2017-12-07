CREATE OR REPLACE FUNCTION Translate(_NodeID integer, _Text text)
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
BEGIN
RETURN COALESCE((Language(_NodeID)).Translation->_Text, _Text);
END;
$$;
