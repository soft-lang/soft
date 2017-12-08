CREATE OR REPLACE FUNCTION Operator_Symbol(_NodeID integer)
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
_Literal text;
BEGIN
SELECT string_agg(Nodes.PrimitiveValue, '' ORDER BY Nodes.NodeID)
INTO STRICT _Literal
FROM Edges
INNER JOIN Nodes  ON Nodes.NodeID   = Edges.ParentNodeID
INNER JOIN Phases ON Phases.PhaseID = Nodes.DeathPhaseID
WHERE Edges.ChildNodeID = _NodeID
AND   Phases.Phase      = 'PARSE';

RETURN _Literal;
END;
$$;
