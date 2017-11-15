CREATE OR REPLACE FUNCTION Soft(
_SourceCode    text,
_Language      text     DEFAULT 'monkey',
_LogSeverity   severity DEFAULT 'NOTICE',
_RunUntilPhase text     DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
-- This function allows quickly invoking a program
-- from source code, without giving it a name.
-- Its name will be the md5() of the source code,
-- so we can detect if we've already compiled it,
-- and if so, it will be reused.
DECLARE
_Program          text;
_ProgramID        integer;
_ProgramNodeID    integer;
_TestID           integer;
_SourceCodeNodeID integer;
_ResultNodeID     integer;
_ResultType       regtype;
_ResultValue      text;
_ResultTypes      regtype[];
_ResultValues     text[];
BEGIN

-- Unnamed program
_Program := md5(_SourceCode);

SELECT Programs.ProgramID
INTO _ProgramID
FROM Programs
INNER JOIN Languages ON Languages.LanguageID = Programs.LanguageID
WHERE Languages.Language = _Language
AND   Programs.Program   = _Program;
IF NOT FOUND THEN
    _ProgramID := New_Program(
        _Language    := _Language,
        _Program     := _Program,
        _LogSeverity := _LogSeverity
    );
    PERFORM New_Node(
        _ProgramID      := _ProgramID,
        _NodeTypeID     := NodeTypes.NodeTypeID,
        _PrimitiveType  := 'text'::regtype,
        _PrimitiveValue := _SourceCode
    )
    FROM NodeTypes
    INNER JOIN Languages ON Languages.LanguageID = NodeTypes.LanguageID
    WHERE Languages.Language = _Language
    AND   NodeTypes.NodeType = 'SOURCE_CODE';
END IF;

RETURN Run(
    _Language      := _Language,
    _Program       := _Program,
    _RunUntilPhase := _RunUntilPhase
);

END;
$$;
