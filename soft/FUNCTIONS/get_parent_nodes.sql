CREATE OR REPLACE FUNCTION Get_Parent_Nodes(_NodeID integer)
RETURNS SETOF integer
LANGUAGE sql
AS $$
WITH RECURSIVE
Parents AS (
SELECT $1 AS ParentNodeID
UNION ALL
SELECT Edges.ParentNodeID FROM Edges
INNER JOIN Parents ON Parents.ParentNodeID = Edges.ChildNodeID
)
SELECT ParentNodeID FROM Parents
$$;
