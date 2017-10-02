CREATE OR REPLACE FUNCTION Get_Node_Attributes(_NodeID integer)
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramNode     boolean;
_Walkable        boolean;
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

IF _Walkable THEN
    _Style := 'wedged';
    _Shape := 'ellipse';
ELSE
    _Style := 'striped';
    _Shape := 'box';
END IF;

_Fillcolor := Get_Node_Color(_NodeID);

IF _ReferenceNodeID IS NOT NULL THEN
    _Fillcolor := _Fillcolor || ':' || Get_Node_Color(_ReferenceNodeID);
END IF;

IF _Fillcolor !~ ':' THEN
    _Style := 'filled';
END IF;

IF _ProgramNode THEN
    _Penwidth := '5';
ELSE
    _Penwidth := '';
END IF;

RETURN format('style="%s" shape="%s" fillcolor="%s" penwidth="%s"', _Style, _Shape, _Fillcolor, _Penwidth);

END;
$$;
