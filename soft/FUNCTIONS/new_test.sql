CREATE OR REPLACE FUNCTION New_Test(
_Language              text,
_Program               text,
_SourceCode            text,
_ExpectedTerminalType  regtype,
_ExpectedTerminalValue text
)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID     integer;
_TerminalType  regtype;
_TerminalValue text;
_OK            boolean;
BEGIN

_ProgramID := New_Program(_Language, _Program);

PERFORM New_Node(
    _Program       := _Program,
    _NodeType      := 'SOURCE_CODE',
    _TerminalType  := 'text'::regtype,
    _TerminalValue := _SourceCode
);

PERFORM Run(_ProgramID := _ProgramID);


INSERT INTO Tests (
    ProgramID,
    TerminalType,
    TerminalValue,
    ExpectedTerminalType,
    ExpectedTerminalValue
)
SELECT
    ProgramID,
    TerminalType,
    TerminalValue,
    _ExpectedTerminalType,
    _ExpectedTerminalValue
FROM Nodes
WHERE NodeID = Get_Program_Node(_ProgramID := _ProgramID)
RETURNING ExpectedTerminalType  = _ExpectedTerminalType
AND       ExpectedTerminalValue = _ExpectedTerminalValue
INTO STRICT _OK;

RETURN _OK;
END;
$$;
