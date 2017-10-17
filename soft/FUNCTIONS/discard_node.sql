CREATE OR REPLACE FUNCTION Discard_Node(_NodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_ChildNodeID integer;
_OK          boolean;
BEGIN

PERFORM Log(
    _NodeID     := _NodeID,
    _Severity   := 'DEBUG3',
    _Message    := format('Discard %s', Node(_NodeID)),
    _SaveDOTIR  := FALSE
);

SELECT Kill_Edge(EdgeID), ChildNodeID INTO STRICT _OK, _ChildNodeID FROM Edges WHERE DeathPhaseID IS NULL AND ParentNodeID = _NodeID;
PERFORM Kill_Node(_NodeID);
PERFORM Set_Program_Node(_NodeID := _ChildNodeID);

RETURN TRUE;
END;
$$;
