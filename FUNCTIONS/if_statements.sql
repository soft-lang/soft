CREATE OR REPLACE FUNCTION soft.If_Statements()
RETURNS boolean
LANGUAGE plpgsql
SET search_path TO soft, public, pg_temp
AS $$
DECLARE
_OK boolean;
_IfNodeID integer;
_BranchNodeID integer;
BEGIN

FOR _IfNodeID IN
SELECT Nodes.NodeID
FROM Nodes
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
WHERE NodeTypes.NodeType = 'IF_STATEMENT'
LOOP
    FOR _BranchNodeID IN
    SELECT Edges.ParentNodeID FROM Edges
    WHERE Edges.ChildNodeID = _IfNodeID
    ORDER BY Edges.EdgeID
    OFFSET 1
    LOOP
        UPDATE Nodes SET Visited = NULL WHERE NodeID = _BranchNodeID RETURNING TRUE INTO STRICT _OK;
    END LOOP;
END LOOP;

RETURN TRUE;
END;
$$;
