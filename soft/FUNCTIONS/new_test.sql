CREATE OR REPLACE FUNCTION New_Test(
_Language       text,
_Program        text,
_SourceCode     text,
_ExpectedType   regtype   DEFAULT NULL,
_ExpectedValue  text      DEFAULT NULL,
_ExpectedTypes  regtype[] DEFAULT NULL,
_ExpectedValues text[]    DEFAULT NULL,
_ExpectedError  text      DEFAULT NULL,
_ExpectedLog    text      DEFAULT NULL
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID        integer;
_ProgramNodeID    integer;
_TestID           integer;
_SourceCodeNodeID integer;
_ResultNodeID     integer;
_ResultType       regtype;
_ResultValue      text;
_ResultTypes      regtype[];
_ResultValues     text[];
_OK               boolean;
_Error            text;
BEGIN

_ProgramID := New_Program(_Language, _Program);

INSERT INTO Tests ( ProgramID,  ExpectedType,  ExpectedValue,  ExpectedTypes,  ExpectedValues,  ExpectedError,  ExpectedLog)
VALUES            (_ProgramID, _ExpectedType, _ExpectedValue, _ExpectedTypes, _ExpectedValues, _ExpectedError, _ExpectedLog)
RETURNING    TestID
INTO STRICT _TestID;

SELECT
    New_Node(
        _ProgramID      := _ProgramID,
        _NodeTypeID     := NodeTypes.NodeTypeID,
        _PrimitiveType  := 'text'::regtype,
        _PrimitiveValue := _SourceCode
    )
INTO STRICT
    _SourceCodeNodeID
FROM NodeTypes
INNER JOIN Languages ON Languages.LanguageID = NodeTypes.LanguageID
WHERE Languages.Language = _Language
AND   NodeTypes.NodeType = 'SOURCE_CODE';

PERFORM Log(
    _NodeID   := _SourceCodeNodeID,
    _Severity := 'DEBUG1',
    _Message  := format('New test %L for language %L', Colorize(_Program,'CYAN'), Colorize(_Language,'MAGENTA'))
);

RETURN _TestID;
END;
$$;
