CREATE OR REPLACE FUNCTION Get_DOT()
RETURNS SETOF text
LANGUAGE plpgsql
AS $$
DECLARE
BEGIN

RETURN QUERY
SELECT format(E'"%s" [label="%s\n%s\n%s\n%s"%s];',
    Nodes.NodeID,
    NodeTypes.NodeType,
    Nodes.TerminalType::text,
    'NodeID ' || Nodes.NodeID || ' : ' || COALESCE(Nodes.TerminalType::text,'NAN') || ' ' || COALESCE(replace(Nodes.TerminalValue,'"','\"'), 'NULL'),
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
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID  = Nodes.NodeTypeID
WHERE Nodes.DeathPhaseID IS NULL;

RETURN QUERY
SELECT format('"%s" -> "%s" [label="%s"];', ParentNodeID, ChildNodeID, 'EdgeID ' || EdgeID)
FROM Edges
WHERE Edges.DeathPhaseID IS NULL;

RETURN;
END;
$$;
