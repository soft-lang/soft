CREATE OR REPLACE FUNCTION Get_Node_Color(_NodeID integer)
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
_EnvironmentID integer;
_Fillcolor     text;
_ColorScheme   text    := 'set312';
_NumColors     integer := 12;
BEGIN

SELECT       EnvironmentID
INTO STRICT _EnvironmentID
FROM Nodes WHERE NodeID = _NodeID;

IF _EnvironmentID = 0 THEN
    _Fillcolor := 'white';
ELSIF _EnvironmentID <= _NumColors THEN
    _Fillcolor := format('/%s/%s', _ColorScheme, _EnvironmentID);
ELSE
    SELECT format('/%s/%s:/%s/%s', _ColorScheme, C1, _ColorScheme, C2)
    INTO _Fillcolor
    FROM (
        SELECT  C1, C2, ROW_NUMBER() OVER ()
        FROM generate_series(1,12) AS C1
        CROSS JOIN generate_series(1,12) AS C2
        WHERE C1 <> C2
    ) AS X
    WHERE ROW_NUMBER = _EnvironmentID;
END IF;

RETURN _Fillcolor;
END;
$$;
