CREATE OR REPLACE FUNCTION "TOKENIZE"."SOURCE_CODE"(_NodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID      integer;
_LanguageID     text;
_SourceCode     text;
_NumChars       integer;
_AtChar         integer;
_Remainder      text;
_Literal        text;
_NodeTypeID     integer;
_TerminalValue  regtype;
_LiteralLength  integer;
_LiteralPattern text;
_Matches        text[];
_Chars          integer[];
_TokenNodeID    integer;
_OK             boolean;
BEGIN

SELECT
    Nodes.ProgramID,
    NodeTypes.LanguageID,
    Nodes.TerminalValue
INTO STRICT
    _ProgramID,
    _LanguageID,
    _SourceCode
FROM Nodes
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
INNER JOIN Programs  ON Programs.ProgramID   = Nodes.ProgramID
INNER JOIN Phases    ON Phases.PhaseID       = Programs.PhaseID
WHERE Nodes.NodeID = _NodeID
AND Phases.Phase       = 'TOKENIZE'
AND NodeTypes.NodeType = 'SOURCE_CODE'
AND Nodes.TerminalType = 'text'::regtype;

_NumChars := length(_SourceCode);

_AtChar := 1;
LOOP
    IF _AtChar > _NumChars THEN
        EXIT;
    END IF;

    _Remainder := substr(_SourceCode, _AtChar);

    IF _Remainder ~ '^\s+' THEN
        _Literal := substring(_Remainder from '^\s+');
        _AtChar := _AtChar + length(_Literal);
        CONTINUE;
    END IF;

    SELECT NodeTypeID,  TerminalValue,  Literal,  LiteralLength
    INTO  _NodeTypeID, _TerminalValue, _Literal, _LiteralLength
    FROM NodeTypes
    WHERE LanguageID = _LanguageID
    AND   Literal    = substr(_SourceCode, _AtChar, LiteralLength)
    ORDER BY LiteralLength DESC
    LIMIT 1;
    IF NOT FOUND THEN
        SELECT  NodeTypeID,  TerminalValue,  LiteralPattern
        INTO   _NodeTypeID, _TerminalValue, _LiteralPattern
        FROM NodeTypes
        WHERE LanguageID = _LanguageID
        AND   _Remainder ~ LiteralPattern
        ORDER BY NodeTypeID
        LIMIT 1;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Unable to tokenize, illegal character at % [%]: %', _AtChar, substr(_SourceCode, _AtChar, 1), _Remainder;
        END IF;
        _Matches       := regexp_matches(_Remainder, _LiteralPattern);
        _Literal       := _Matches[2];
        _LiteralLength := length(_Matches[1]);
    END IF;

     SELECT array_agg(Chars.C) INTO STRICT _Chars FROM generate_series(_AtChar, _AtChar+_LiteralLength-1) AS Chars(C);


CREATE OR REPLACE FUNCTION New_Node(
_ProgramID            integer,
_NodeTypeID           integer,
_TerminalValue        text      DEFAULT NULL,
_TerminalType         regtype   DEFAULT NULL,
_SourceCodeCharacters integer[] DEFAULT NULL
)

    _TokenNodeID := New_Node(
        _ProgramID := 
        _NodeTypeID, _Literal, _TerminalValue, _Chars);

    INSERT INTO Edges (     ParentNodeID,  ChildNodeID)
    VALUES            (_SourceCodeNodeID, _TokenNodeID)
    RETURNING TRUE INTO STRICT _OK;

    _AtChar := _AtChar + _LiteralLength;
END LOOP;

RETURN TRUE;
END;
$$;
