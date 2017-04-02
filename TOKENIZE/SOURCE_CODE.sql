CREATE OR REPLACE FUNCTION "TOKENIZE"."SOURCE_CODE"(_NodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID            integer;
_LanguageID           integer;
_SourceCode           text;
_PhaseID              integer;
_NumChars             integer;
_AtChar               integer;
_Remainder            text;
_NodeTypeID           integer;
_NodeType             text;
_TerminalType         regtype;
_Literal              text;
_LiteralLength        integer;
_LiteralPattern       text;
_Matches              text[];
_SourceCodeCharacters integer[];
_IllegalCharacters    integer[];
_TokenNodeID          integer;
_OK                   boolean;
_Tokens               integer;
_LogSeverity          severity;
BEGIN

SELECT
    Nodes.ProgramID,
    NodeTypes.LanguageID,
    Nodes.TerminalValue,
    Programs.PhaseID,
    Languages.LogSeverity
INTO STRICT
    _ProgramID,
    _LanguageID,
    _SourceCode,
    _PhaseID,
    _LogSeverity
FROM Nodes
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
INNER JOIN Programs  ON Programs.ProgramID   = Nodes.ProgramID
INNER JOIN Phases    ON Phases.PhaseID       = Programs.PhaseID
INNER JOIN Languages ON Languages.LanguageID = Phases.LanguageID
WHERE Nodes.NodeID = _NodeID
AND Phases.Phase       = 'TOKENIZE'
AND NodeTypes.NodeType = 'SOURCE_CODE'
AND Nodes.TerminalType = 'text'::regtype;

_NumChars := length(_SourceCode);

_AtChar := 1;
_Tokens := 0;
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

    SELECT NodeTypeID,  NodeType,  TerminalType,  Literal,  LiteralLength
    INTO  _NodeTypeID, _NodeType, _TerminalType, _Literal, _LiteralLength
    FROM NodeTypes
    WHERE LanguageID = _LanguageID
    AND   Literal    = substr(_SourceCode, _AtChar, LiteralLength)
    ORDER BY LiteralLength DESC
    LIMIT 1;
    IF NOT FOUND THEN
        SELECT  NodeTypeID,  NodeType, TerminalType,  LiteralPattern
        INTO   _NodeTypeID, _NodeType, _TerminalType, _LiteralPattern
        FROM NodeTypes
        WHERE LanguageID = _LanguageID
        AND   _Remainder ~ LiteralPattern
        ORDER BY NodeTypeID
        LIMIT 1;
        IF NOT FOUND THEN
            _IllegalCharacters := _IllegalCharacters || _AtChar;
            _AtChar := _AtChar + 1;
            CONTINUE;
        END IF;
        _Matches       := regexp_matches(_Remainder, _LiteralPattern);
        _Literal       := _Matches[2];
        _LiteralLength := length(_Matches[1]);
    END IF;

    SELECT array_agg(Chars.C) INTO STRICT _SourceCodeCharacters FROM generate_series(_AtChar, _AtChar+_LiteralLength-1) AS Chars(C);

    _TokenNodeID := New_Node(
        _ProgramID            := _ProgramID,
        _NodeTypeID           := _NodeTypeID,
        _TerminalType         := _TerminalType,
        _TerminalValue        := _Literal,
        _SourceCodeCharacters := _SourceCodeCharacters
    );
    _Tokens := _Tokens + 1;

    IF _LogSeverity < 'DEBUG2' THEN
        PERFORM Log(
            _NodeID   := _NodeID,
            _Severity := _LogSeverity,
            _Message  := format('%s <- %s',
                Colorize(_NodeType, 'CYAN'),
                CASE _LogSeverity
                WHEN 'DEBUG3' THEN Colorize(One_Line(_Literal), 'MAGENTA')
                ELSE Colorize(_Literal, 'MAGENTA')
                END
            )
        );
    END IF;

    PERFORM New_Edge(
        _ProgramID    := _ProgramID,
        _ParentNodeID := _NodeID,
        _ChildNodeID  := _TokenNodeID
    );

    _AtChar := _AtChar + _LiteralLength;
END LOOP;

IF _IllegalCharacters IS NOT NULL THEN
    PERFORM Log(
        _NodeID               := _NodeID,
        _Severity             := 'ERROR',
        _Message              := 'Illegal characters',
        _SourceCodeCharacters := _IllegalCharacters
    );
    RETURN FALSE;
ELSE
    PERFORM Log(
        _NodeID               := _NodeID,
        _Severity             := 'INFO',
        _Message              := format('OK, created %s tokens from %s characters', _Tokens, _NumChars)
    );
    RETURN TRUE;
END IF;

END;
$$;
