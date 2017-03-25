CREATE OR REPLACE FUNCTION soft.Pop_Node(_VariableNodeID integer)
RETURNS boolean
LANGUAGE plpgsql
SET search_path TO soft, public, pg_temp
AS $$
DECLARE
_NewNodeID integer;
_OK boolean;
BEGIN
IF NOT EXISTS (SELECT 1 FROM Edges WHERE ChildNodeID = _VariableNodeID) THEN
    RAISE EXCEPTION 'Unable to pop % since it has no parents', _VariableNodeID;
END IF;
DELETE FROM Edges WHERE ChildNodeID = _VariableNodeID RETURNING ParentNodeID INTO STRICT _NewNodeID;
PERFORM Copy_Node(_NewNodeID, _VariableNodeID);
IF EXISTS (SELECT 1 FROM Edges WHERE ChildNodeID = _NewNodeID) THEN
    UPDATE Edges SET ChildNodeID = _VariableNodeID WHERE ChildNodeID = _NewNodeID RETURNING TRUE INTO STRICT _OK;
END IF;
DELETE FROM Nodes WHERE NodeID = _NewNodeID RETURNING TRUE INTO STRICT _OK;
RETURN TRUE;
END;
$$;
