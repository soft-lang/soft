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
    Get_Node_Lexical_Environment(Nodes.NodeID),
    Nodes.NodeID,
    Node(Nodes.NodeID),
    Serialize_Node(Nodes.NodeID),
    Get_Node_Attributes(Nodes.NodeID, _NodeID)
)
FROM Nodes
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
WHERE Nodes.ProgramID = _ProgramID
AND Nodes.DeathPhaseID IS NULL
ORDER BY Nodes.NodeID;

RETURN QUERY
SELECT DISTINCT format(E'"%s.%s" [label="%s" %s];',
    Get_Node_Lexical_Environment(Edges.ChildNodeID),
    Nodes.NodeID,
    Node(Nodes.NodeID),
    Get_Node_Attributes(Nodes.NodeID, _NodeID)
)
FROM Nodes
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
INNER JOIN Edges     ON Edges.ParentNodeID   = Nodes.NodeID
WHERE Nodes.ProgramID = _ProgramID
AND   Nodes.DeathPhaseID IS NULL
AND   Edges.DeathPhaseID IS NULL
AND   Get_Node_Lexical_Environment(Nodes.NodeID) <> Get_Node_Lexical_Environment(Edges.ChildNodeID)
ORDER BY 1;

RETURN QUERY
SELECT DISTINCT format(E'"%s.%s" [label="%s" %s];',
    Get_Node_Lexical_Environment(Edges.ParentNodeID),
    Nodes.NodeID,
    Node(Nodes.NodeID),
    Get_Node_Attributes(Nodes.NodeID, _NodeID)
)
FROM Nodes
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
INNER JOIN Edges     ON Edges.ChildNodeID    = Nodes.NodeID
WHERE Nodes.ProgramID = _ProgramID
AND   Nodes.DeathPhaseID IS NULL
AND   Edges.DeathPhaseID IS NULL
AND   Get_Node_Lexical_Environment(Nodes.NodeID) <> Get_Node_Lexical_Environment(Edges.ParentNodeID)
ORDER BY 1;

RETURN QUERY
SELECT format FROM (
    SELECT
        EdgeID,
        format('"%s.%s" -> "%s.%s";',
                Get_Node_Lexical_Environment(ParentNodeID),
                ParentNodeID,
                Get_Node_Lexical_Environment(ChildNodeID),
                ChildNodeID
        )
    FROM Edges
    WHERE ProgramID = _ProgramID
    AND DeathPhaseID IS NULL
    AND Get_Node_Lexical_Environment(ParentNodeID) = Get_Node_Lexical_Environment(ChildNodeID)
    UNION ALL
    SELECT
        EdgeID,
        format('"%s.%s" -> "%s.%s";',
            Get_Node_Lexical_Environment(ChildNodeID),
            ParentNodeID,
            Get_Node_Lexical_Environment(ChildNodeID),
            ChildNodeID
        )
    FROM Edges
    WHERE ProgramID = _ProgramID
    AND DeathPhaseID IS NULL
    AND Get_Node_Lexical_Environment(ParentNodeID) <> Get_Node_Lexical_Environment(ChildNodeID)
    UNION ALL
    SELECT
        EdgeID,
        format('"%s.%s" -> "%s.%s";',
            Get_Node_Lexical_Environment(ParentNodeID),
            ParentNodeID,
            Get_Node_Lexical_Environment(ParentNodeID),
            ChildNodeID,
            EdgeID
        )
    FROM Edges
    WHERE ProgramID = _ProgramID
    AND DeathPhaseID IS NULL
    AND Get_Node_Lexical_Environment(ParentNodeID) <> Get_Node_Lexical_Environment(ChildNodeID)
) AS X
ORDER BY EdgeID;

RETURN;
END;
$$;
