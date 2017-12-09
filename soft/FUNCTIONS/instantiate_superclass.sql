CREATE OR REPLACE FUNCTION Instantiate_SuperClass(_ClassDeclarationNodeID integer, _SuperClassNodeID integer)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_CloneNodeID integer;
_ClassNodeID integer;
_OK          boolean;
BEGIN
RAISE NOTICE '_ClassDeclarationNodeID % _SuperClassNodeID %', _ClassDeclarationNodeID, _SuperClassNodeID;

PERFORM Kill_Edge(Edge(_ClassDeclarationNodeID, _SuperClassNodeID));

SELECT Clone(_ClassDeclarationNodeID, _EnvironmentID := EnvironmentID)
INTO STRICT _CloneNodeID
FROM Nodes WHERE NodeID = _SuperClassNodeID;

PERFORM Change_Node_Type(_CloneNodeID, _OldNodeType := 'CLASS_DECLARATION', _NewNodeType := 'SUPERCLASS');

UPDATE Nodes
SET NodeName = Node_Name(_SuperClassNodeID)
WHERE NodeID = _CloneNodeID
RETURNING TRUE INTO STRICT _OK;

_ClassNodeID := Child(_SuperClassNodeID);

PERFORM New_Edge(_CloneNodeID, _ClassNodeID);

PERFORM Kill_Edge(Edge(_SuperClassNodeID, _ClassNodeID));

PERFORM Kill_Node(_SuperClassNodeID);

RETURN _CloneNodeID;
END;
$$;
