CREATE OR REPLACE FUNCTION Get_Node_Attributes(_NodeID integer)
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramNode boolean;
_Walkable    boolean;
_Env         integer;
_Style       text;
_Shape       text;
_Fillcolor   text;
_Penwidth    text;
_ColorScheme text    := 'set312';
_NumColors   integer := 12;
BEGIN

SELECT
    Nodes.NodeID = Programs.NodeID,
    Nodes.Walkable
INTO
    _ProgramNode,
    _Walkable
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
    _Fillcolor := format('/%s/%s:/%s/%s', _ColorScheme, _Env/_NumColors, _ColorScheme, _Env%_NumColors+1);
END IF;

IF _ProgramNode THEN
    _Penwidth := '5';
ELSE
    _Penwidth := '';
END IF;

RETURN format('style="%s" shape="%s" fillcolor="%s" penwidth="%s"', _Style, _Shape, _Fillcolor, _Penwidth);

END;
$$;
