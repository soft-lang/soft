CREATE OR REPLACE FUNCTION "MAP_FUNCTIONS"."ENTER_RET"(_NodeID integer) RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_FunctionLabelNodeID integer;
_ProgramID           integer;
_ChildNodeID         integer;
_OK                  boolean;
BEGIN

IF Find_Node(
    _NodeID  := _NodeID,
    _Descend := FALSE,
    _Strict  := FALSE,
    _Paths   := ARRAY['-> PROGRAM']
) IS NOT NULL THEN
    RETURN FALSE;
END IF;


_FunctionLabelNodeID := Find_Node(
    _NodeID  := _NodeID,
    _Descend := FALSE,
    _Strict  := TRUE,
    _Paths   := ARRAY['-> FUNCTION_DECLARATION -> FUNCTION_LABEL']
);

SELECT
    Nodes.ProgramID,
    Edges.ChildNodeID
INTO STRICT
    _ProgramID,
    _ChildNodeID
FROM Edges
INNER JOIN Nodes     ON Nodes.NodeID         = Edges.ChildNodeID
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
WHERE Edges.ParentNodeID = _FunctionLabelNodeID
AND   Edges.DeathPhaseID IS NULL
AND   Nodes.DeathPhaseID IS NULL
AND   NodeTypes.NodeType <> 'CALL';

UPDATE Programs SET NodeID = _ChildNodeID WHERE ProgramID = _ProgramID AND NodeID = _NodeID RETURNING TRUE INTO STRICT _OK;

RETURN TRUE;
END;
$$;
