CREATE OR REPLACE FUNCTION Push_Node(_VariableNodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID integer;
_NewNodeID integer;
_EdgeID    integer;
_OK        boolean;
BEGIN

SELECT
    ProgramID,
    New_Node(
        _ProgramID     := ProgramID,
        _NodeTypeID    := NodeTypeID,
        _TerminalType  := TerminalType,
        _TerminalValue := TerminalValue
    )
INTO STRICT
    _ProgramID,
    _NewNodeID
FROM Nodes WHERE NodeID = _VariableNodeID;

PERFORM Copy_Node(_VariableNodeID, _NewNodeID);

UPDATE Nodes SET
    TerminalType  = NULL,
    TerminalValue = NULL
WHERE NodeID = _VariableNodeID
AND DeathPhaseID IS NULL
RETURNING TRUE INTO STRICT _OK;

PERFORM Set_Edge_Child(_EdgeID := EdgeID, _ChildNodeID := _NewNodeID) FROM Edges WHERE DeathPhaseID IS NULL AND ChildNodeID = _VariableNodeID;

PERFORM New_Edge(
    _ProgramID    := _ProgramID,
    _ParentNodeID := _NewNodeID,
    _ChildNodeID  := _VariableNodeID
);

RETURN TRUE;
END;
$$;
