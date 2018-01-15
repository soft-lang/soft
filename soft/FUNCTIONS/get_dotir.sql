CREATE OR REPLACE FUNCTION Get_DOTIR(_CurrentNodeID integer, _PrevNodeID integer)
RETURNS SETOF text
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID     integer;
_FamilyNodeIDs integer[];
BEGIN

/*
WITH
Parents              AS (SELECT ParentNodeID AS NodeID FROM Edges WHERE ChildNodeID  = _CurrentNodeID AND DeathPhaseID IS NULL),
Siblings             AS (SELECT ChildNodeID  AS NodeID FROM Edges WHERE ParentNodeID IN (SELECT NodeID FROM Parents)         AND DeathPhaseID IS NULL),
GrandParents         AS (SELECT ParentNodeID AS NodeID FROM Edges WHERE ChildNodeID  IN (SELECT NodeID FROM Parents)         AND DeathPhaseID IS NULL),
GrandSiblings        AS (SELECT ChildNodeID  AS NodeID FROM Edges WHERE ParentNodeID IN (SELECT NodeID FROM GrandParents)    AND DeathPhaseID IS NULL),
Children             AS (SELECT ChildNodeID  AS NodeID FROM Edges WHERE ParentNodeID = _CurrentNodeID AND DeathPhaseID IS NULL),
ChildrenParents      AS (SELECT ParentNodeID AS NodeID FROM Edges WHERE ChildNodeID  IN (SELECT NodeID FROM Children)        AND DeathPhaseID IS NULL),
ChildrenGrandParents AS (SELECT ParentNodeID AS NodeID FROM Edges WHERE ChildNodeID  IN (SELECT NodeID FROM ChildrenParents) AND DeathPhaseID IS NULL),
GrandChildren        AS (SELECT ChildNodeID  AS NodeID FROM Edges WHERE ParentNodeID IN (SELECT NodeID FROM Children)        AND DeathPhaseID IS NULL),
GrandChildrenParents AS (SELECT ParentNodeID AS NodeID FROM Edges WHERE ChildNodeID  IN (SELECT NodeID FROM GrandChildren)   AND DeathPhaseID IS NULL)
SELECT array_agg(NodeID) INTO _FamilyNodeIDs FROM (
    SELECT _CurrentNodeID AS NodeID
    UNION ALL SELECT NodeID FROM Parents
    UNION ALL SELECT NodeID FROM Siblings
    UNION ALL SELECT NodeID FROM GrandParents
    UNION ALL SELECT NodeID FROM GrandSiblings
    UNION ALL SELECT NodeID FROM Children
    UNION ALL SELECT NodeID FROM ChildrenParents
    UNION ALL SELECT NodeID FROM ChildrenGrandParents
    UNION ALL SELECT NodeID FROM GrandChildren
    UNION ALL SELECT NodeID FROM GrandChildrenParents
) AS Family;
*/

SELECT       ProgramID
INTO STRICT _ProgramID
FROM Nodes
WHERE NodeID = _CurrentNodeID;

SELECT array_agg(NodeID) INTO _FamilyNodeIDs FROM Nodes WHERE ProgramID = _ProgramID;

RETURN QUERY
SELECT format(E'"%s.%s" [label="%s" %s];',
    Nodes.EnvironmentID,
    Nodes.NodeID,
    replace(Node(Nodes.NodeID),'"',''),
    Get_Node_Attributes(Nodes.NodeID, _CurrentNodeID, _PrevNodeID)
)
FROM Nodes
WHERE Nodes.ProgramID = _ProgramID
AND Nodes.DeathPhaseID IS NULL
AND Nodes.NodeID = ANY(_FamilyNodeIDs)
ORDER BY Nodes.NodeID;

RETURN QUERY
SELECT DISTINCT format(E'"%s.%s" [label="%s" %s];',
    Child.EnvironmentID,
    Parent.NodeID,
    replace(Node(Parent.NodeID),'"',''),
    Get_Node_Attributes(Parent.NodeID, _CurrentNodeID, _PrevNodeID)
)
FROM Nodes AS Parent
INNER JOIN Edges          ON Edges.ParentNodeID = Parent.NodeID
INNER JOIN Nodes AS Child ON Child.NodeID       = Edges.ChildNodeID
WHERE Parent.ProgramID    = _ProgramID
AND   Parent.DeathPhaseID IS NULL
AND   Edges.DeathPhaseID  IS NULL
AND   Edges.ParentNodeID = ANY(_FamilyNodeIDs)
AND   Edges.ChildNodeID  = ANY(_FamilyNodeIDs)
AND   Parent.EnvironmentID <> Child.EnvironmentID
ORDER BY 1;

RETURN QUERY
SELECT DISTINCT format(E'"%s.%s" [label="%s" %s];',
    Parent.EnvironmentID,
    Child.NodeID,
    replace(Node(Child.NodeID),'"',''),
    Get_Node_Attributes(Child.NodeID, _CurrentNodeID, _PrevNodeID)
)
FROM Nodes AS Child
INNER JOIN Edges           ON Edges.ChildNodeID = Child.NodeID
INNER JOIN Nodes AS Parent ON Parent.NodeID     = Edges.ParentNodeID
WHERE Child.ProgramID = _ProgramID
AND   Child.DeathPhaseID IS NULL
AND   Edges.DeathPhaseID IS NULL
AND   Edges.ParentNodeID = ANY(_FamilyNodeIDs)
AND   Edges.ChildNodeID  = ANY(_FamilyNodeIDs)
AND   Child.EnvironmentID <> Parent.EnvironmentID
ORDER BY 1;

RETURN QUERY
SELECT format FROM (
    SELECT
        Edges.EdgeID,
        format('"%s.%s" -> "%s.%s";',
                Parent.EnvironmentID,
                Edges.ParentNodeID,
                Child.EnvironmentID,
                Edges.ChildNodeID
        )
    FROM Edges
    INNER JOIN Nodes AS Parent ON Parent.NodeID = Edges.ParentNodeID
    INNER JOIN Nodes AS Child  ON Child.NodeID  = Edges.ChildNodeID
    WHERE Edges.ProgramID = _ProgramID
    AND Edges.DeathPhaseID IS NULL
    AND Parent.EnvironmentID = Child.EnvironmentID
    AND Edges.ParentNodeID = ANY(_FamilyNodeIDs)
    AND Edges.ChildNodeID  = ANY(_FamilyNodeIDs)
    UNION
    SELECT
        Edges.EdgeID,
        format('"%s.%s" -> "%s.%s";',
            Child.EnvironmentID,
            Edges.ParentNodeID,
            Child.EnvironmentID,
            Edges.ChildNodeID
        )
    FROM Edges
    INNER JOIN Nodes AS Parent ON Parent.NodeID = Edges.ParentNodeID
    INNER JOIN Nodes AS Child  ON Child.NodeID  = Edges.ChildNodeID
    WHERE Edges.ProgramID = _ProgramID
    AND Edges.DeathPhaseID IS NULL
    AND Parent.EnvironmentID <> Child.EnvironmentID
    AND Edges.ParentNodeID = ANY(_FamilyNodeIDs)
    AND Edges.ChildNodeID  = ANY(_FamilyNodeIDs)
    UNION
    SELECT
        Edges.EdgeID,
        format('"%s.%s" -> "%s.%s";',
            Parent.EnvironmentID,
            Edges.ParentNodeID,
            Parent.EnvironmentID,
            Edges.ChildNodeID
        )
    FROM Edges
    INNER JOIN Nodes AS Parent ON Parent.NodeID = Edges.ParentNodeID
    INNER JOIN Nodes AS Child  ON Child.NodeID  = Edges.ChildNodeID
    WHERE Edges.ProgramID = _ProgramID
    AND Edges.DeathPhaseID IS NULL
    AND Parent.EnvironmentID <> Child.EnvironmentID
    AND Edges.ParentNodeID = ANY(_FamilyNodeIDs)
    AND Edges.ChildNodeID  = ANY(_FamilyNodeIDs)
) AS X
ORDER BY EdgeID;

RETURN;
END;
$$;
