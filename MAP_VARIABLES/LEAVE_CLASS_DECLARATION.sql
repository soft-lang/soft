CREATE OR REPLACE FUNCTION "MAP_VARIABLES"."LEAVE_CLASS_DECLARATION"(_NodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_ParentNodeIDs integer[];
_NameNodeID    integer;
_MethodNodeID  integer;
_OK            boolean;
BEGIN
PERFORM Set_Walkable(_NodeID, FALSE);

SELECT array_agg(ParentNodeID ORDER BY EdgeID)
INTO _ParentNodeIDs
FROM Edges
WHERE ChildNodeID = _NodeID
AND   DeathPhaseID IS NULL;

IF array_length(_ParentNodeIDs,1) % 2 <> 0 THEN
    RAISE EXCEPTION 'Uneven parent nodes % to class NodeID %', _ParentNodeIDs, _NodeID;
END IF;

FOR _i IN 1..array_length(_ParentNodeIDs,1)/2 LOOP
    _NameNodeID   := _ParentNodeIDs[_i*2-1];
    _MethodNodeID := _ParentNodeIDs[_i*2];
    IF Node_Type(_NameNodeID) IS DISTINCT FROM 'VARIABLE' THEN
        RAISE EXCEPTION 'Expected name node % to be of type VARIABLE but is %', _NameNodeID, Node_Type(_NameNodeID);
    END IF;
    IF Node_Type(_MethodNodeID) IS DISTINCT FROM 'FUNCTION_DECLARATION' THEN
        RAISE EXCEPTION 'Expected method node % to be of type FUNCTION_DECLARATION but is %', _MethodNodeID, Node_Type(_MethodNodeID);
    END IF;

    UPDATE Nodes SET NodeName = (
        SELECT NodeName FROM Nodes WHERE NodeID = _NameNodeID
    ) WHERE NodeID = _MethodNodeID
    RETURNING TRUE INTO STRICT _OK;

    SELECT Kill_Edge(EdgeID) INTO STRICT _OK FROM Edges WHERE ParentNodeID = _NameNodeID AND ChildNodeID = _NodeID;

    PERFORM Kill_Node(_NameNodeID);
END LOOP;

RETURN TRUE;
END;
$$;
