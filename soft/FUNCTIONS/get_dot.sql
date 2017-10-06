CREATE OR REPLACE FUNCTION Get_DOT(_Language text, _Program text)
RETURNS SETOF text
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID integer;
BEGIN

SELECT Programs.ProgramID
INTO STRICT    _ProgramID
FROM Programs
INNER JOIN Languages ON Languages.LanguageID = Programs.LanguageID
WHERE Languages.Language = _Language
AND   Programs.Program   = _Program;

RETURN QUERY
SELECT format(E'"%s.%s" [label="%s" %s];',
    Get_Env(Nodes.NodeID),
    Nodes.NodeID,
    Get_Node_Label(Nodes.NodeID),
    Get_Node_Attributes(Nodes.NodeID)
)
FROM Nodes
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
WHERE Nodes.ProgramID = _ProgramID
AND Nodes.DeathPhaseID IS NULL;

RETURN QUERY
SELECT format('"%s.%s" -> "%s.%s";', Get_Env(ParentNodeID), ParentNodeID, Get_Env(ChildNodeID), ChildNodeID)
FROM Edges
WHERE Edges.ProgramID = _ProgramID
AND Edges.DeathPhaseID IS NULL
AND Get_Env(ParentNodeID) = Get_Env(ChildNodeID);

RETURN QUERY
SELECT DISTINCT format(E'"%s.%s" [label="%s" %s];',
    Get_Env(Edges.ChildNodeID),
    Nodes.NodeID,
    Get_Node_Label(Nodes.NodeID),
    Get_Node_Attributes(Nodes.NodeID)
)
FROM Nodes
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
INNER JOIN Edges     ON Edges.ParentNodeID   = Nodes.NodeID
WHERE Nodes.ProgramID = _ProgramID
AND   Nodes.DeathPhaseID IS NULL
AND   Edges.DeathPhaseID IS NULL
AND   Get_Env(Nodes.NodeID) <> Get_Env(Edges.ChildNodeID);

RETURN QUERY
SELECT DISTINCT format(E'"%s.%s" [label="%s" %s];',
    Get_Env(Edges.ParentNodeID),
    Nodes.NodeID,
    Get_Node_Label(Nodes.NodeID),
    Get_Node_Attributes(Nodes.NodeID)
)
FROM Nodes
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
INNER JOIN Edges     ON Edges.ChildNodeID    = Nodes.NodeID
WHERE Nodes.ProgramID = _ProgramID
AND   Nodes.DeathPhaseID IS NULL
AND   Edges.DeathPhaseID IS NULL
AND   Get_Env(Nodes.NodeID) <> Get_Env(Edges.ParentNodeID);

RETURN QUERY
SELECT format('"%s.%s" -> "%s.%s";', Get_Env(ChildNodeID), ParentNodeID, Get_Env(ChildNodeID), ChildNodeID)
FROM Edges
WHERE Edges.ProgramID = _ProgramID
AND Edges.DeathPhaseID IS NULL
AND Get_Env(ParentNodeID) <> Get_Env(ChildNodeID);

RETURN QUERY
SELECT format('"%s.%s" -> "%s.%s";', Get_Env(ParentNodeID), ParentNodeID, Get_Env(ParentNodeID), ChildNodeID)
FROM Edges
WHERE Edges.ProgramID = _ProgramID
AND Edges.DeathPhaseID IS NULL
AND Get_Env(ParentNodeID) <> Get_Env(ChildNodeID);

RETURN;
END;
$$;
