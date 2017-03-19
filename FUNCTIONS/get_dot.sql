CREATE OR REPLACE FUNCTION soft.Get_DOT()
RETURNS SETOF text
LANGUAGE plpgsql
SET search_path TO soft, public, pg_temp
AS $$
DECLARE
BEGIN

RETURN QUERY
SELECT format(E'"%s" [label="%s\n%s\n%s\n%s"%s];',
    Nodes.NodeID,
    NodeTypes.NodeType,
    Nodes.ValueType::text,
    Nodes.Visited,
    'NodeID ' || Nodes.NodeID || ' : ' || COALESCE(Nodes.ValueType::text,'NAN') || ' ' || COALESCE(CASE Nodes.BooleanValue WHEN TRUE THEN 'TRUE' WHEN FALSE THEN 'FALSE' ELSE COALESCE(Nodes.BooleanValue::text, Nodes.IntegerValue::text, Nodes.TextValue, Nodes.NameValue, NodeTypes.Literal, 'NULL') END),
    CASE
    WHEN Programs.NodeID = Nodes.NodeID THEN ' style="filled" fillcolor="red"'
    WHEN Nodes.Visited > 0 THEN ' style="filled" fillcolor="grey"'
    END
--      COALESCE(CASE Nodes.BooleanValue WHEN TRUE THEN 'TRUE' WHEN FALSE THEN 'FALSE' ELSE COALESCE(Nodes.NameValue::text, Nodes.BooleanValue::text, Nodes.NumericValue::text, Nodes.IntegerValue::text, Nodes.TextValue, NodeTypes.Literal, 'NULL') END)
)
FROM Nodes
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID  = Nodes.NodeTypeID
LEFT JOIN Programs   ON Programs.NodeID = Nodes.NodeID;

RETURN QUERY
SELECT format('"%s" -> "%s" [label="%s"];', ParentNodeID, ChildNodeID, 'EdgeID ' || EdgeID)
--  SELECT format('"%s" -> "%s";', ParentNodeID, ChildNodeID)
FROM Edges;

RETURN;
END;
$$;
