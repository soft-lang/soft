CREATE OR REPLACE FUNCTION soft.Delete_Source_Code_Node()
RETURNS boolean
LANGUAGE plpgsql
SET search_path TO soft, public, pg_temp
AS $$
DECLARE
_SourceCodeNodeID integer;
_OK boolean;
BEGIN

SELECT NodeID INTO STRICT _SourceCodeNodeID FROM Nodes
WHERE NOT EXISTS (
    SELECT 1 FROM Edges WHERE Edges.ChildNodeID = Nodes.NodeID
);

DELETE FROM Edges WHERE ParentNodeID = _SourceCodeNodeID;

DELETE FROM Nodes WHERE NodeID = _SourceCodeNodeID RETURNING TRUE INTO STRICT _OK;

RETURN TRUE;
END;
$$;
