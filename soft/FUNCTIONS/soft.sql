CREATE OR REPLACE FUNCTION Soft(
_Language    text,
_SourceCode  text,
_LogSeverity severity DEFAULT 'NOTICE'
)
RETURNS TABLE (
OK             boolean,
Error          text,
PrimitiveType  regtype,
PrimitiveValue text
)
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

SELECT
    Run.OK,
    Run.Error
INTO STRICT
    OK,
    Error
FROM Run(_Language, _Program);

IF NOT OK THEN
    RETURN;
END IF;

_ResultNodeID := Dereference((SELECT NodeID FROM Programs WHERE ProgramID = _ProgramID));

RETURN QUERY
SELECT
    OK,
    Error,
    Nodes.PrimitiveType,
    Nodes.PrimitiveValue
FROM Nodes
WHERE NodeID = _ResultNodeID
AND Nodes.PrimitiveType IS NOT NULL;
IF NOT FOUND THEN
    RETURN QUERY
    SELECT
        OK,
        Error,
        Primitive_Type(Nodes.NodeID),
        Primitive_Value(Nodes.NodeID)
    FROM Edges
    INNER JOIN Nodes ON Nodes.NodeID = Edges.ParentNodeID
    WHERE Edges.ChildNodeID = _ResultNodeID
    AND Edges.DeathPhaseID IS NULL
    AND Nodes.DeathPhaseID IS NULL
    ORDER BY Edges.EdgeID;
END IF;

RETURN;
END;
$$;
