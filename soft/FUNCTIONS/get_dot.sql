CREATE OR REPLACE FUNCTION Get_DOT()
RETURNS SETOF text
LANGUAGE plpgsql
AS $$
DECLARE
BEGIN

RETURN QUERY
SELECT format(E'"%s.%s" [label="%s\n%s\n%s\n%s"%s];',
    Get_Env(Nodes.NodeID),
    Nodes.NodeID,
    NodeTypes.NodeType,
    Nodes.PrimitiveType::text,
    'NodeID ' || Nodes.NodeID || ' : ' || COALESCE(Nodes.PrimitiveType::text,'NAN') || ' ' || COALESCE(replace(Nodes.PrimitiveValue,'"','\"'), 'Ref: '||Nodes.ReferenceNodeID::text, 'NULL'),
    (SELECT Phases.Phase FROM Programs INNER JOIN Phases USING (PhaseID)),
    CASE
        WHEN Nodes.Walkable IS NOT NULL
        THEN ' style="filled"'
            || CASE WHEN Nodes.NodeID = (SELECT NodeID FROM Programs) THEN ' penwidth="5"' ELSE '' END
            || ' fillcolor="'
            || CASE WHEN Nodes.NodeID = (SELECT NodeID FROM Programs) THEN CASE (SELECT Direction FROM Programs) WHEN 'ENTER' THEN 'cyan' WHEN 'LEAVE' THEN 'yellow' END ELSE CASE Nodes.Walkable WHEN TRUE THEN 'grey' WHEN FALSE THEN 'white' END END
            || '"'
        ELSE ''
    END
)
FROM Nodes
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
WHERE Nodes.DeathPhaseID IS NULL;

RETURN QUERY
SELECT format('"%s.%s" -> "%s.%s" [label="%s"];', Get_Env(ParentNodeID), ParentNodeID, Get_Env(ChildNodeID), ChildNodeID, 'EdgeID ' || EdgeID)
FROM Edges
WHERE Edges.DeathPhaseID IS NULL
AND Get_Env(ParentNodeID) = Get_Env(ChildNodeID);

RETURN QUERY
SELECT DISTINCT format(E'"%s.%s" [label="%s\n%s\n%s\n%s"%s];',
    Get_Env(Edges.ChildNodeID),
    Nodes.NodeID,
    NodeTypes.NodeType,
    Nodes.PrimitiveType::text,
    'NodeID ' || Nodes.NodeID || ' : ' || COALESCE(Nodes.PrimitiveType::text,'NAN') || ' ' || COALESCE(replace(Nodes.PrimitiveValue,'"','\"'), 'Ref: '||Nodes.ReferenceNodeID::text, 'NULL'),
    (SELECT Phases.Phase FROM Programs INNER JOIN Phases USING (PhaseID)),
    CASE
        WHEN Nodes.Walkable IS NOT NULL
        THEN ' style="filled"'
            || CASE WHEN Nodes.NodeID = (SELECT NodeID FROM Programs) THEN ' penwidth="5"' ELSE '' END
            || ' fillcolor="'
            || CASE WHEN Nodes.NodeID = (SELECT NodeID FROM Programs) THEN CASE (SELECT Direction FROM Programs) WHEN 'ENTER' THEN 'cyan' WHEN 'LEAVE' THEN 'yellow' END ELSE CASE Nodes.Walkable WHEN TRUE THEN 'grey' WHEN FALSE THEN 'white' END END
            || '"'
        ELSE ''
    END
)
FROM Nodes
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
INNER JOIN Edges     ON Edges.ParentNodeID   = Nodes.NodeID
WHERE Nodes.DeathPhaseID IS NULL
AND   Edges.DeathPhaseID IS NULL
AND   Get_Env(Nodes.NodeID) <> Get_Env(Edges.ChildNodeID);

RETURN QUERY
SELECT DISTINCT format(E'"%s.%s" [label="%s\n%s\n%s\n%s"%s];',
    Get_Env(Edges.ParentNodeID),
    Nodes.NodeID,
    NodeTypes.NodeType,
    Nodes.PrimitiveType::text,
    'NodeID ' || Nodes.NodeID || ' : ' || COALESCE(Nodes.PrimitiveType::text,'NAN') || ' ' || COALESCE(replace(Nodes.PrimitiveValue,'"','\"'), 'Ref: '||Nodes.ReferenceNodeID::text, 'NULL'),
    (SELECT Phases.Phase FROM Programs INNER JOIN Phases USING (PhaseID)),
    CASE
        WHEN Nodes.Walkable IS NOT NULL
        THEN ' style="filled"'
            || CASE WHEN Nodes.NodeID = (SELECT NodeID FROM Programs) THEN ' penwidth="5"' ELSE '' END
            || ' fillcolor="'
            || CASE WHEN Nodes.NodeID = (SELECT NodeID FROM Programs) THEN CASE (SELECT Direction FROM Programs) WHEN 'ENTER' THEN 'cyan' WHEN 'LEAVE' THEN 'yellow' END ELSE CASE Nodes.Walkable WHEN TRUE THEN 'grey' WHEN FALSE THEN 'white' END END
            || '"'
        ELSE ''
    END
)
FROM Nodes
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
INNER JOIN Edges     ON Edges.ChildNodeID    = Nodes.NodeID
WHERE Nodes.DeathPhaseID IS NULL
AND   Edges.DeathPhaseID IS NULL
AND   Get_Env(Nodes.NodeID) <> Get_Env(Edges.ParentNodeID);

RETURN QUERY
SELECT format('"%s.%s" -> "%s.%s" [label="%s"];', Get_Env(ChildNodeID), ParentNodeID, Get_Env(ChildNodeID), ChildNodeID, 'EdgeID ' || EdgeID)
FROM Edges
WHERE Edges.DeathPhaseID IS NULL
AND Get_Env(ParentNodeID) <> Get_Env(ChildNodeID);

RETURN QUERY
SELECT format('"%s.%s" -> "%s.%s" [label="%s"];', Get_Env(ParentNodeID), ParentNodeID, Get_Env(ParentNodeID), ChildNodeID, 'EdgeID ' || EdgeID)
FROM Edges
WHERE Edges.DeathPhaseID IS NULL
AND Get_Env(ParentNodeID) <> Get_Env(ChildNodeID);

RETURN;
END;
$$;
