CREATE OR REPLACE FUNCTION Get_Node_Attributes(_NodeID integer)
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramNode     boolean;
_Walkable        boolean;
_Env             integer;
_Style           text;
_Shape           text;
_Fillcolor       text;
_Penwidth        text;
_ColorScheme     text    := 'set312';
_NumColors       integer := 12;
_ReferenceNodeID integer;
BEGIN

SELECT
    Nodes.NodeID = Programs.NodeID,
    Nodes.Walkable,
    Nodes.ReferenceNodeID
INTO
    _ProgramNode,
    _Walkable,
    _ReferenceNodeID
FROM Nodes
INNER JOIN Programs ON Programs.ProgramID = Nodes.ProgramID
WHERE Nodes.NodeID = _NodeID;

_Env := Get_Env(_NodeID);

IF _Walkable THEN
    _Style := 'wedged';
    _Shape := 'ellipse';
ELSE
    _Style := 'striped';
    _Shape := 'box';
END IF;

IF _Env < _NumColors THEN
    _Style := 'filled';
    _Fillcolor := format('/%s/%s', _ColorScheme, _Env+1);
ELSE
    SELECT format('/%s/%s:/%s/%s', _ColorScheme, C1, _ColorScheme, C2)
    INTO _Fillcolor
    FROM (
        SELECT  C1, C2, ROW_NUMBER() OVER ()
        FROM generate_series(1,12) AS C1
        CROSS JOIN generate_series(1,12) AS C2
        WHERE C1 <> C2
    ) AS X
    WHERE ROW_NUMBER = _Env;
END IF;

IF _ProgramNode THEN
    _Penwidth := '5';
ELSE
    _Penwidth := '';
END IF;

RETURN format('style="%s" shape="%s" fillcolor="%s" penwidth="%s"', _Style, _Shape, _Fillcolor, _Penwidth);

END;
$$;
