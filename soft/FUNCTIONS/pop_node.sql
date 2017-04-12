CREATE OR REPLACE FUNCTION Pop_Node(_VariableNodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_NewNodeID integer;
_OK        boolean;
BEGIN

IF NOT EXISTS (SELECT 1 FROM Edges WHERE DeathPhaseID IS NULL AND ChildNodeID = _VariableNodeID) THEN
    RAISE EXCEPTION 'Unable to pop % since it has no parents', _VariableNodeID;
END IF;

SELECT Kill_Edge(EdgeID), ParentNodeID INTO STRICT _OK, _NewNodeID FROM Edges WHERE DeathPhaseID IS NULL AND ChildNodeID = _VariableNodeID;

PERFORM Copy_Node(_NewNodeID, _VariableNodeID);

PERFORM Set_Edge_Child(_EdgeID := EdgeID, _ChildNodeID := _VariableNodeID) FROM Edges WHERE DeathPhaseID IS NULL AND ChildNodeID = _NewNodeID;

PERFORM Kill_Node(_NewNodeID);

RETURN TRUE;
END;
$$;
