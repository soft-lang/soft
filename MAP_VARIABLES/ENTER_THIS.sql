CREATE OR REPLACE FUNCTION "MAP_VARIABLES"."ENTER_THIS"(_NodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_ClassNodeID integer;
_ProgramID   integer;
_OK          boolean;
BEGIN

_ClassNodeID := Find_Node(_NodeID := _NodeID, _Descend := TRUE, _Strict := TRUE, _Path := '-> CLASS_DECLARATION');

SELECT ProgramID INTO STRICT _ProgramID FROM Nodes WHERE NodeID = _NodeID;

UPDATE Programs SET Direction = 'LEAVE' WHERE ProgramID = _ProgramID RETURNING TRUE INTO STRICT _OK;
PERFORM Next_Node(_ProgramID);

SELECT Set_Edge_Parent(EdgeID, _ParentNodeID := _ClassNodeID) INTO STRICT _OK FROM Edges WHERE DeathPhaseID IS NULL AND ParentNodeID = _NodeID;
PERFORM Kill_Node(_NodeID);

RETURN TRUE;
END;
$$;
