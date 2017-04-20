CREATE OR REPLACE FUNCTION New_Test(
_Language      text,
_Program       text,
_SourceCode    text,
_ExpectedType  regtype,
_ExpectedValue text
)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID     integer;
_NodeID        integer;
_TerminalType  regtype;
_TerminalValue text;
_OK            boolean;
BEGIN

_ProgramID := New_Program(_Language, _Program);

_NodeID := New_Node(
    _Program       := _Program,
    _NodeType      := 'SOURCE_CODE',
    _TerminalType  := 'text'::regtype,
    _TerminalValue := _SourceCode
);

PERFORM Log(
    _NodeID   := _NodeID,
    _Severity := 'DEBUG3',
    _Message  := format('New test %L for language %L', Colorize(_Program,'CYAN'), Colorize(_Language,'MAGENTA'))
);

PERFORM Run(_ProgramID := _ProgramID);

RETURN _OK;

INSERT INTO Tests (
    ProgramID,
    TerminalType,
    TerminalValue,
    ExpectedType,
    ExpectedValue
)
SELECT
    ProgramID,
    TerminalType,
    TerminalValue,
    _ExpectedType,
    _ExpectedValue
FROM Nodes
WHERE NodeID = Get_Program_Node(_ProgramID := _ProgramID)
RETURNING TerminalType  = _ExpectedType
AND       TerminalValue = _ExpectedValue
INTO STRICT _OK;

PERFORM Log(
    _NodeID   := _NodeID,
    _Severity := 'NOTICE',
    _Message  := format('Test %L %s for language %L',
        Colorize(_Program),
        CASE WHEN _OK
        THEN Colorize('OK', 'GREEN')
        ELSE Colorize('FAILED', 'RED')
        END,
        Colorize(_Language)
    )
);

RETURN _OK;
END;
$$;
