CREATE OR REPLACE FUNCTION Leave_Node(_NodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID integer;
_PhaseID   integer;
_Phase     text;
_NodeType  text;
_Function  text;
_Direction direction;
_OK        boolean;
BEGIN

SELECT Programs.ProgramID, Programs.PhaseID, Phases.Phase, NodeTypes.NodeType
INTO STRICT    _ProgramID,         _PhaseID,       _Phase,          _NodeType
FROM Nodes
INNER JOIN Programs  ON Programs.ProgramID   = Nodes.ProgramID
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
INNER JOIN Phases    ON Phases.PhaseID       = Programs.PhaseID
WHERE Nodes.NodeID       = _NodeID
AND   Programs.Direction = 'LEAVE'
FOR UPDATE OF Nodes, Programs;

_Function := 'LEAVE_' || _NodeType;

IF EXISTS (
    SELECT 1 FROM pg_proc
    INNER JOIN pg_namespace ON pg_namespace.oid = pg_proc.pronamespace
    WHERE pg_namespace.nspname = _Phase
    AND   pg_proc.proname      = _Function
) THEN
    PERFORM Log(
        _NodeID   := _NodeID,
        _Severity := 'DEBUG3',
        _Message  := format('Execute function %I.%I', Colorize(_Phase, 'CYAN'), Colorize(_Function, 'MAGENTA'))
    );
    EXECUTE format('SELECT %I.%I(_NodeID := %s::integer)', _Phase, _Function, _NodeID);
    RETURN TRUE;
ELSE
    RETURN NULL;
END IF;

END;
$$;
