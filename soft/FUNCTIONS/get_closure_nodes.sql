CREATE OR REPLACE FUNCTION Get_Closure_Nodes(_FunctionDeclarationNodeID integer)
RETURNS SETOF integer
LANGUAGE plpgsql
AS $$
/*
If a function is declared within a loop,
and any of the variables within the function
are declared outside of the function
but within the loop body,
then the function is a closure,
and all such variables are closure variables.
*/
DECLARE
_LoopNodeID integer;
BEGIN

_LoopNodeID := Find_Node(_NodeID := _FunctionDeclarationNodeID, _Descend := TRUE, _Strict := TRUE, _Paths := ARRAY['-> FOR_BODY', '-> WHILE_BODY']);

RETURN QUERY
WITH RECURSIVE Children AS (
    SELECT
        Edges.ChildNodeID,
        ARRAY[Edges.ChildNodeID] AS ChildNodeIDs
    FROM Edges
    INNER JOIN Nodes AS ChildNode ON ChildNode.NodeID = Edges.ChildNodeID
    WHERE Edges.ParentNodeID     = Child(_FunctionDeclarationNodeID)
    AND   Edges.DeathPhaseID     IS NULL
    AND   ChildNode.DeathPhaseID IS NULL
    AND   ChildNode.Walkable     IS TRUE
    UNION ALL
    SELECT
        Edges.ChildNodeID,
        Edges.ChildNodeID || Children.ChildNodeIDs AS ChildNodeIDs
    FROM Edges
    INNER JOIN Nodes AS ChildNode ON ChildNode.NodeID     = Edges.ChildNodeID
    INNER JOIN Children           ON Children.ChildNodeID = Edges.ParentNodeID
    WHERE    Edges.DeathPhaseID IS NULL
    AND ChildNode.DeathPhaseID IS NULL
    AND NOT Edges.ChildNodeID = ANY(Children.ChildNodeIDs)
    AND Edges.ChildNodeID    <> _LoopNodeID
)
SELECT Variable.NodeID
FROM Children
INNER JOIN LATERAL (
    SELECT NthParent(Edges.ParentNodeID, _Nth := 1, _AssertNodeType := 'VARIABLE') AS NodeID
    FROM Edges
    INNER JOIN Nodes     ON Nodes.NodeID         = Edges.ParentNodeID
    INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
    WHERE Edges.ChildNodeID  = Children.ChildNodeID
    AND   NodeTypes.NodeType = 'DECLARATION'
) AS Variable ON TRUE
WHERE Is_Ancestor_To(_AncestorNodeID := Variable.NodeID, _DescendantNodeID := _FunctionDeclarationNodeID)
AND Variable.NodeID <> Left(_FunctionDeclarationNodeID);

END;
$$;
