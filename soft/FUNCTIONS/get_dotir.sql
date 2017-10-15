CREATE OR REPLACE FUNCTION Get_DOTIR(_NodeID integer)
RETURNS SETOF text
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID integer;
BEGIN

SELECT       ProgramID
INTO STRICT _ProgramID
FROM Nodes
WHERE NodeID = _NodeID;

RETURN QUERY
SELECT format(E'"%s.%s" [label="%s" dotir="%s" %s];',
    Nodes.Environment,
    Nodes.NodeID,
    Node(Nodes.NodeID),
    Serialize_Node(Nodes.NodeID),
    Get_Node_Attributes(Nodes.NodeID, _NodeID)
)
FROM Nodes
WHERE Nodes.ProgramID = _ProgramID
AND Nodes.DeathPhaseID IS NULL
ORDER BY Nodes.NodeID;

RETURN QUERY
SELECT DISTINCT format(E'"%s.%s" [label="%s" %s];',
    Child.Environment,
    Parent.NodeID,
    Node(Parent.NodeID),
    Get_Node_Attributes(Parent.NodeID, _NodeID)
)
FROM Nodes AS Parent
INNER JOIN Edges          ON Edges.ParentNodeID = Parent.NodeID
INNER JOIN Nodes AS Child ON Child.NodeID       = Edges.ChildNodeID
WHERE Parent.ProgramID    = _ProgramID
AND   Parent.DeathPhaseID IS NULL
AND   Edges.DeathPhaseID  IS NULL
AND   Parent.Environment <> Child.Environment
ORDER BY 1;

RETURN QUERY
SELECT DISTINCT format(E'"%s.%s" [label="%s" %s];',
    Parent.Environment,
    Child.NodeID,
    Node(Child.NodeID),
    Get_Node_Attributes(Child.NodeID, _NodeID)
)
FROM Nodes AS Child
INNER JOIN Edges           ON Edges.ChildNodeID = Child.NodeID
INNER JOIN Nodes AS Parent ON Parent.NodeID     = Edges.ParentNodeID
WHERE Child.ProgramID = _ProgramID
AND   Child.DeathPhaseID IS NULL
AND   Edges.DeathPhaseID IS NULL
AND   Child.Environment <> Parent.Environment
ORDER BY 1;

RETURN QUERY
SELECT format FROM (
    SELECT
        Edges.EdgeID,
        format('"%s.%s" -> "%s.%s";',
                Parent.Environment,
                Edges.ParentNodeID,
                Child.Environment,
                Edges.ChildNodeID
        )
    FROM Edges
    INNER JOIN Nodes AS Parent ON Parent.NodeID = Edges.ParentNodeID
    INNER JOIN Nodes AS Child  ON Child.NodeID  = Edges.ChildNodeID
    WHERE Edges.ProgramID = _ProgramID
    AND Edges.DeathPhaseID IS NULL
    AND Parent.Environment = Child.Environment
    UNION
    SELECT
        Edges.EdgeID,
        format('"%s.%s" -> "%s.%s";',
            Child.Environment,
            Edges.ParentNodeID,
            Child.Environment,
            Edges.ChildNodeID
        )
    FROM Edges
    INNER JOIN Nodes AS Parent ON Parent.NodeID = Edges.ParentNodeID
    INNER JOIN Nodes AS Child  ON Child.NodeID  = Edges.ChildNodeID
    WHERE Edges.ProgramID = _ProgramID
    AND Edges.DeathPhaseID IS NULL
    AND Parent.Environment <> Child.Environment
    UNION
    SELECT
        Edges.EdgeID,
        format('"%s.%s" -> "%s.%s";',
            Parent.Environment,
            Edges.ParentNodeID,
            Parent.Environment,
            Edges.ChildNodeID
        )
    FROM Edges
    INNER JOIN Nodes AS Parent ON Parent.NodeID = Edges.ParentNodeID
    INNER JOIN Nodes AS Child  ON Child.NodeID  = Edges.ChildNodeID
    WHERE Edges.ProgramID = _ProgramID
    AND Edges.DeathPhaseID IS NULL
    AND Parent.Environment <> Child.Environment
) AS X
ORDER BY EdgeID;

RETURN;
END;
$$;
