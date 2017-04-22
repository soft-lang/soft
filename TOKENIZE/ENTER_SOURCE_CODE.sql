CREATE OR REPLACE FUNCTION "TOKENIZE"."ENTER_SOURCE_CODE"(_NodeID integer)
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
_IllegalCharacters    integer[];
_TokenNodeID          integer;
_OK                   boolean;
_Tokens               integer;
_LogSeverity          severity;
_NodeSeverity         severity;
_Wrapping             text[];
_RecreatedSourceCode  text;
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
    _Wrapping  := NULL;

    SELECT NodeTypeID,  NodeType,  TerminalType,  Literal,  LiteralLength,  NodeSeverity
    INTO  _NodeTypeID, _NodeType, _TerminalType, _Literal, _LiteralLength, _NodeSeverity
    FROM NodeTypes
    WHERE LanguageID = _LanguageID
    AND   Literal    = substr(_SourceCode, _AtChar, LiteralLength)
    ORDER BY LiteralLength DESC
    LIMIT 1;
    IF NOT FOUND THEN
        SELECT  NodeTypeID,  NodeType,  TerminalType,  LiteralPattern,  NodeSeverity
        INTO   _NodeTypeID, _NodeType, _TerminalType, _LiteralPattern, _NodeSeverity
        FROM NodeTypes
        WHERE LanguageID = _LanguageID
        AND  _Remainder  ~  LiteralPattern
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

        IF EXISTS (SELECT 1 FROM NodeTypes WHERE LanguageID = _LanguageID AND GrowFromNodeTypeID = _NodeTypeID AND _Literal ~ LiteralPattern) THEN
            SELECT       NodeTypeID,  NodeType,  TerminalType,  LiteralPattern,  NodeSeverity
            INTO STRICT _NodeTypeID, _NodeType, _TerminalType, _LiteralPattern, _NodeSeverity
            FROM NodeTypes
            WHERE LanguageID         = _LanguageID
            AND   GrowFromNodeTypeID = _NodeTypeID
            AND  _Literal            ~  LiteralPattern
            ORDER BY NodeTypeID
            LIMIT 1;
            _Matches       := regexp_matches(_Literal, _LiteralPattern);
            _Literal       := _Matches[2];
            _LiteralLength := length(_Matches[1]);
        END IF;
    END IF;

    IF _LiteralLength > length(_Literal) THEN
        _Wrapping := regexp_split_to_array(_Matches[1], _Literal);
        IF (array_length(_Wrapping,1) <> 2) THEN
            RAISE EXCEPTION 'Expected exactly two array elements but got: %', _Wrapping;
        END IF;
    END IF;

    IF _Wrapping[1] <> '' THEN
        PERFORM Kill_Node(_NodeID :=  New_Node(
            _ProgramID            := _ProgramID,
            _NodeTypeID           := _NodeTypeID,
            _TerminalType         := _TerminalType,
            _TerminalValue        := _Wrapping[1]
        ));
        _Tokens := _Tokens + 1;
    END IF;

    _TokenNodeID := New_Node(
        _ProgramID            := _ProgramID,
        _NodeTypeID           := _NodeTypeID,
        _TerminalType         := _TerminalType,
        _TerminalValue        := _Literal
    );
    _Tokens := _Tokens + 1;

    IF _Wrapping[2] <> '' THEN
        PERFORM Kill_Node(_NodeID :=  New_Node(
            _ProgramID            := _ProgramID,
            _NodeTypeID           := _NodeTypeID,
            _TerminalType         := _TerminalType,
            _TerminalValue        := _Wrapping[2]
        ));
        _Tokens := _Tokens + 1;
    END IF;

    PERFORM Log(
        _NodeID   := _NodeID,
        _Severity := COALESCE(_NodeSeverity, 'DEBUG2'),
        _Message  := format('%s <- %s',
            Colorize(Node(_TokenNodeID), 'CYAN'),
            Colorize(One_Line(_Literal), 'MAGENTA')
        )
    );

    PERFORM New_Edge(
        _ProgramID    := _ProgramID,
        _ParentNodeID := _TokenNodeID,
        _ChildNodeID  := _NodeID
    );

    _AtChar := _AtChar + _LiteralLength;
END LOOP;

IF _IllegalCharacters IS NOT NULL THEN
    RAISE EXCEPTION E'Illegal characters:\n%', Highlight_Characters(
        _Text       := _SourceCode,
        _Characters := _IllegalCharacters,
        _Color      := 'RED'
    )
    USING HINT = 'Define a catch-all node type e.g. LiteralPattern (.) with e.g. node severity ERROR as the last LiteralPattern node type';
END IF;

SELECT array_to_string(array_agg(TerminalValue ORDER BY NodeID),'')
INTO STRICT _RecreatedSourceCode
FROM Nodes
WHERE ProgramID  = _ProgramID
AND BirthPhaseID = _PhaseID
AND NodeID       > _NodeID;

IF _RecreatedSourceCode IS DISTINCT FROM _SourceCode THEN
    RAISE EXCEPTION E'Unable to recreate source code from created token nodes.\nSourceCode "%"\nIS DISTINCT FROM\nRecreatedSourceCode "%"',
        Colorize(_SourceCode, 'CYAN'),
        Colorize(_RecreatedSourceCode, 'MAGENTA')
    ;
END IF;

PERFORM Log(
    _NodeID   := _NodeID,
    _Severity := 'INFO',
    _Message  := format('OK, created %s tokens from %s characters', _Tokens, _NumChars)
);
RETURN TRUE;

END;
$$;
