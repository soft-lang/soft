CREATE OR REPLACE FUNCTION Get_DOT()
RETURNS SETOF text
LANGUAGE plpgsql
AS $$
DECLARE
BEGIN

RETURN QUERY
SELECT format(E'"%s" [label="%s\n%s\n%s"%s];',
    Nodes.NodeID,
    NodeTypes.NodeType,
    Nodes.TerminalType::text,
    'NodeID ' || Nodes.NodeID || ' : ' || COALESCE(Nodes.TerminalType::text,'NAN') || ' ' || COALESCE(replace(Nodes.TerminalValue,'"','\"'), 'NULL'),
    CASE
    WHEN Nodes.BirthPhaseID > 1 THEN ' style="filled" fillcolor="grey"'
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
