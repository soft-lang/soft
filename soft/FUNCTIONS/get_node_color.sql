CREATE OR REPLACE FUNCTION Get_Node_Color(_NodeID integer)
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
_Environment integer;
_Fillcolor   text;
_ColorScheme text    := 'set312';
_NumColors   integer := 12;
BEGIN

SELECT       Environment
INTO STRICT _Environment
FROM Nodes WHERE NodeID = _NodeID;

IF _Environment = 0 THEN
    _Fillcolor := 'white';
ELSIF _Environment <= _NumColors THEN
    _Fillcolor := format('/%s/%s', _ColorScheme, _Environment);
ELSE
    SELECT format('/%s/%s:/%s/%s', _ColorScheme, C1, _ColorScheme, C2)
    INTO _Fillcolor
    FROM (
        SELECT  C1, C2, ROW_NUMBER() OVER ()
        FROM generate_series(1,12) AS C1
        CROSS JOIN generate_series(1,12) AS C2
        WHERE C1 <> C2
    ) AS X
    WHERE ROW_NUMBER = _Environment;
END IF;

RETURN _Fillcolor;
END;
$$;
