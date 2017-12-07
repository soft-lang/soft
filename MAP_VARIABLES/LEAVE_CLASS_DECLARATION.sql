CREATE OR REPLACE FUNCTION "MAP_VARIABLES"."LEAVE_CLASS_DECLARATION"(_NodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_ParentNodeIDs    integer[];
_NameNodeID       integer;
_MethodNodeID     integer;
_SuperNameNodeID  integer;
_SuperClassNodeID integer;
_OK               boolean;
BEGIN
PERFORM Set_Walkable(_NodeID, FALSE);

SELECT array_agg(ParentNodeID ORDER BY EdgeID)
INTO _ParentNodeIDs
FROM Edges
WHERE ChildNodeID = _NodeID
AND   DeathPhaseID IS NULL;

_SuperNameNodeID := Parent(_NodeID, _NodeType := 'SUPERCLASS');
IF _SuperNameNodeID IS NOT NULL THEN
    _ParentNodeIDs := array_remove(_ParentNodeIDs, _SuperNameNodeID);
    _SuperClassNodeID := Find_Node(
        _NodeID := Find_Node(
            _NodeID                    := _NodeID,
            _Descend                   := TRUE,
            _Strict                    := TRUE,
            _Names                     := ARRAY[Node_Name(_SuperNameNodeID)],
            _MustBeDeclaredAfter       := TRUE,
            _SelectLastIfMultipleMatch := TRUE,
            _Path                      := '<- DECLARATION <- VARIABLE[1]',
            _ErrorType                 := 'UNDEFINED_SUPERCLASS'
        ),
        _Descend   := FALSE,
        _Strict    := TRUE,
        _Path      := '-> DECLARATION <- CLASS_DECLARATION',
        _ErrorType := 'SUPERCLASS_MUST_BE_CLASS'
    );
    IF _SuperClassNodeID IS NULL THEN
        RETURN NULL;
    END IF;
    PERFORM New_Edge(
        _ParentNodeID := _SuperClassNodeID,
        _ChildNodeID  := _SuperNameNodeID
    );
    PERFORM Set_Walkable(_SuperNameNodeID, FALSE);
END IF;

IF (array_length(_ParentNodeIDs,1) > 0) IS NOT TRUE THEN
    -- Empty class
    RETURN TRUE;
END IF;

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
