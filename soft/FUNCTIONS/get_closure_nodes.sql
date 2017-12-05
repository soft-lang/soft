CREATE OR REPLACE FUNCTION Get_Closure_Nodes(_FunctionDeclarationNodeID integer)
RETURNS SETOF integer
LANGUAGE sql
AS $$
SELECT
    NthParent
FROM (
    SELECT
        NthParent(Edges.ParentNodeID, _Nth := 1, _AssertNodeType := 'VARIABLE')
    FROM Edges
    INNER JOIN Nodes     ON Nodes.NodeID         = Edges.ParentNodeID
    INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
    WHERE Edges.ChildNodeID = Child(Child($1,'DECLARATION'))
    AND   Edges.DeathPhaseID IS NULL
    AND   Nodes.DeathPhaseID IS NULL
    AND   NodeTypes.NodeType = 'DECLARATION'
) AS VariablesDeclaredAtSameLevel
WHERE Is_Ancestor_To(_AncestorNodeID := NthParent, _DescendantNodeID := $1)
AND   NthParent <> Left($1)
$$;
