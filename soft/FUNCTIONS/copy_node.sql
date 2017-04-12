CREATE OR REPLACE FUNCTION Copy_Node(_FromNodeID integer, _ToNodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_TerminalValue text;
BEGIN

UPDATE Nodes AS CopyTo SET
    TerminalType    = CopyFrom.TerminalType,
    TerminalValue   = CopyFrom.TerminalValue
FROM Nodes AS CopyFrom
WHERE CopyFrom.NodeID = _FromNodeID
AND     CopyTo.NodeID = _ToNodeID
RETURNING CopyTo.TerminalValue INTO STRICT _TerminalValue;

PERFORM Log(
    _NodeID   := _FromNodeID,
    _Severity := 'DEBUG3',
    _Message  := format('Copied "%s" from node %s to %s', Colorize(_TerminalValue), Colorize(Node(_FromNodeID),'CYAN'), Colorize(Node(_ToNodeID),'CYAN'))
);

RETURN TRUE;
END;
$$;
