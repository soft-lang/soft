CREATE OR REPLACE FUNCTION Get_DOT(_ProgramID integer)
RETURNS SETOF text
LANGUAGE plpgsql
AS $$
DECLARE
BEGIN

RETURN QUERY
SELECT format(E'"%s.%s" [label="%s" %s];',
    Get_Node_Lexical_Environment(Nodes.NodeID),
    Nodes.NodeID,
    Node(Nodes.NodeID),
    Get_Node_Attributes(Nodes.NodeID)
)
FROM Nodes
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
WHERE Nodes.ProgramID = _ProgramID
AND Nodes.DeathPhaseID IS NULL;

RETURN QUERY
SELECT format('"%s.%s" -> "%s.%s";', Get_Node_Lexical_Environment(ParentNodeID), ParentNodeID, Get_Node_Lexical_Environment(ChildNodeID), ChildNodeID)
FROM Edges
WHERE Edges.ProgramID = _ProgramID
AND Edges.DeathPhaseID IS NULL
AND Get_Node_Lexical_Environment(ParentNodeID) = Get_Node_Lexical_Environment(ChildNodeID);

RETURN QUERY
SELECT DISTINCT format(E'"%s.%s" [label="%s" %s];',
    Get_Node_Lexical_Environment(Edges.ChildNodeID),
    Nodes.NodeID,
    Node(Nodes.NodeID),
    Get_Node_Attributes(Nodes.NodeID)
)
FROM Nodes
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
INNER JOIN Edges     ON Edges.ParentNodeID   = Nodes.NodeID
WHERE Nodes.ProgramID = _ProgramID
AND   Nodes.DeathPhaseID IS NULL
AND   Edges.DeathPhaseID IS NULL
AND   Get_Node_Lexical_Environment(Nodes.NodeID) <> Get_Node_Lexical_Environment(Edges.ChildNodeID);

RETURN QUERY
SELECT DISTINCT format(E'"%s.%s" [label="%s" %s];',
    Get_Node_Lexical_Environment(Edges.ParentNodeID),
    Nodes.NodeID,
    Node(Nodes.NodeID),
    Get_Node_Attributes(Nodes.NodeID)
)
FROM Nodes
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
INNER JOIN Edges     ON Edges.ChildNodeID    = Nodes.NodeID
WHERE Nodes.ProgramID = _ProgramID
AND   Nodes.DeathPhaseID IS NULL
AND   Edges.DeathPhaseID IS NULL
AND   Get_Node_Lexical_Environment(Nodes.NodeID) <> Get_Node_Lexical_Environment(Edges.ParentNodeID);

RETURN QUERY
SELECT format('"%s.%s" -> "%s.%s";', Get_Node_Lexical_Environment(ChildNodeID), ParentNodeID, Get_Node_Lexical_Environment(ChildNodeID), ChildNodeID)
FROM Edges
WHERE Edges.ProgramID = _ProgramID
AND Edges.DeathPhaseID IS NULL
AND Get_Node_Lexical_Environment(ParentNodeID) <> Get_Node_Lexical_Environment(ChildNodeID);

RETURN QUERY
SELECT format('"%s.%s" -> "%s.%s";', Get_Node_Lexical_Environment(ParentNodeID), ParentNodeID, Get_Node_Lexical_Environment(ParentNodeID), ChildNodeID)
FROM Edges
WHERE Edges.ProgramID = _ProgramID
AND Edges.DeathPhaseID IS NULL
AND Get_Node_Lexical_Environment(ParentNodeID) <> Get_Node_Lexical_Environment(ChildNodeID);

RETURN;
END;
$$;
