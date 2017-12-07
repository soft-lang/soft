CREATE OR REPLACE FUNCTION "TOKENIZE"."ENTER_SOURCE_CODE"(_NodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_Program             text;
_ProgramID           integer;
_LanguageID          integer;
_SourceCode          text;
_PhaseID             integer;
_NumChars            integer;
_AtChar              integer;
_Remainder           text;
_NodeTypeID          integer;
_NodeType            text;
_PrimitiveType       regtype;
_Literal             text;
_LiteralLength       integer;
_LiteralPattern      text;
_Matches             text[];
_IllegalCharacters   integer[];
_TokenNodeID         integer;
_OK                  boolean;
_Tokens              integer;
_NodeSeverity        severity;
_Wrapping            text[];
_RecreatedSourceCode text;
BEGIN

PERFORM Log(
    _NodeID   := _NodeID,
    _Severity := COALESCE(_NodeSeverity, 'DEBUG1'),
    _Message  := 'Tokenizing begins',
    _SaveDOTIR  := TRUE
);

SELECT
    Nodes.ProgramID,
    NodeTypes.LanguageID,
    Nodes.PrimitiveValue,
    Programs.PhaseID,
    Programs.Program
INTO STRICT
    _ProgramID,
    _LanguageID,
    _SourceCode,
    _PhaseID,
    _Program
FROM Nodes
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
INNER JOIN Programs  ON Programs.ProgramID   = Nodes.ProgramID
INNER JOIN Phases    ON Phases.PhaseID       = Programs.PhaseID
INNER JOIN Languages ON Languages.LanguageID = Phases.LanguageID
WHERE Nodes.NodeID      = _NodeID
--AND Phases.Phase        = 'TOKENIZE'
--AND NodeTypes.NodeType  = 'SOURCE_CODE'
AND Nodes.PrimitiveType = 'text'::regtype;

_NumChars := length(_SourceCode);

_AtChar := 1;
_Tokens := 0;
LOOP
    IF _AtChar > _NumChars THEN
        EXIT;
    END IF;

    _Remainder := substr(_SourceCode, _AtChar);
    _Wrapping  := NULL;

    SELECT NodeTypeID,  NodeType,  PrimitiveType,  Literal,  LiteralLength,  NodeSeverity
    INTO  _NodeTypeID, _NodeType, _PrimitiveType, _Literal, _LiteralLength, _NodeSeverity
    FROM NodeTypes
    WHERE LanguageID = _LanguageID
    AND   Literal    = substr(_SourceCode, _AtChar, LiteralLength)
    ORDER BY LiteralLength DESC
    LIMIT 1;
    IF NOT FOUND THEN
        SELECT  NodeTypeID,  NodeType,  PrimitiveType,  LiteralPattern,  NodeSeverity
        INTO   _NodeTypeID, _NodeType, _PrimitiveType, _LiteralPattern, _NodeSeverity
        FROM NodeTypes
        WHERE LanguageID = _LanguageID
        AND  _Remainder  ~  ('^('||LiteralPattern||')')
        ORDER BY NodeTypeID
        LIMIT 1;
        IF NOT FOUND THEN
            _IllegalCharacters := _IllegalCharacters || _AtChar;
            _AtChar := _AtChar + 1;
            CONTINUE;
        END IF;
        _LiteralPattern := '^('||_LiteralPattern||')';
        _Matches        := regexp_matches(_Remainder, _LiteralPattern);
        _LiteralLength  := length(_Matches[1]);

        IF array_length(_Matches,1) = 2 THEN
            -- One single inner capture group, no wrapping: ^((content))
            _Wrapping := NULL;
            _Literal  := _Matches[2];
        ELSIF array_length(_Matches,1) = 4 THEN
            -- Three inner capture groups: ^((wrapping)(content)(wrapping))
            _Wrapping := ARRAY[_Matches[2], _Matches[4]];
            _Literal  := _Matches[3];
        ELSE
            RAISE EXCEPTION 'Unexpected capture groups: NodeType % Literal % LiteralPattern % Matches %', _NodeType, _Literal, _LiteralPattern, _Matches;
        END IF;

        IF EXISTS (
            SELECT 1 FROM NodeTypes
            WHERE LanguageID         = _LanguageID
            AND   GrowFromNodeTypeID = _NodeTypeID
            AND  _Literal            ~ ('^('||LiteralPattern||')')
        ) THEN
            SELECT       NodeTypeID,  NodeType,  PrimitiveType,  LiteralPattern,  NodeSeverity
            INTO STRICT _NodeTypeID, _NodeType, _PrimitiveType, _LiteralPattern, _NodeSeverity
            FROM NodeTypes
            WHERE LanguageID         = _LanguageID
            AND   GrowFromNodeTypeID = _NodeTypeID
            AND  _Literal            ~  ('^('||LiteralPattern||')')
            ORDER BY NodeTypeID
            LIMIT 1;
            _LiteralPattern := '^('||_LiteralPattern||')';
            _Matches        := regexp_matches(_Literal, _LiteralPattern);
            _LiteralLength  := length(_Matches[1]);

            IF array_length(_Matches,1) = 2 THEN
                -- One single inner capture group, no wrapping: ^((content))
                _Wrapping := NULL;
                _Literal  := _Matches[2];
            ELSIF array_length(_Matches,1) = 4 THEN
                -- Three inner capture groups: ^((wrapping)(content)(wrapping))
                _Wrapping := ARRAY[_Matches[2], _Matches[4]];
                _Literal  := _Matches[3];
            ELSE
                RAISE EXCEPTION 'Unexpected capture groups: NodeType % Literal % LiteralPattern % Matches %', _NodeType, _Literal, _LiteralPattern, _Matches;
            END IF;
        END IF;

    END IF;

    IF _Wrapping[1] <> '' THEN
        PERFORM Kill_Node(
            _NodeID :=  New_Node(
                _ProgramID      := _ProgramID,
                _NodeTypeID     := _NodeTypeID,
                _PrimitiveType  := _PrimitiveType,
                _PrimitiveValue := _Wrapping[1]
            )
        );
        _Tokens := _Tokens + 1;
    END IF;

    _TokenNodeID := New_Node(
        _ProgramID      := _ProgramID,
        _NodeTypeID     := _NodeTypeID,
        _PrimitiveType  := _PrimitiveType,
        _PrimitiveValue := _Literal
    );
    _Tokens := _Tokens + 1;

    IF _Wrapping[2] <> '' THEN
        -- To be able to verify we are able to
        -- recreate the source code *exactly*,
        -- we need to preserve the wrapping,
        -- such as e.g. the two " in a
        -- double-quoted string,
        -- but we want it dead during our phase,
        -- since we don't want to bother the
        -- next phase with nonsense.
        PERFORM Kill_Node(
            _NodeID :=  New_Node(
                _ProgramID      := _ProgramID,
                _NodeTypeID     := _NodeTypeID,
                _PrimitiveType  := _PrimitiveType,
                _PrimitiveValue := _Wrapping[2]
            )
        );
        _Tokens := _Tokens + 1;
    END IF;

    PERFORM New_Edge(
        _ParentNodeID := _TokenNodeID,
        _ChildNodeID  := _NodeID
    );

    IF _NodeSeverity IS NOT NULL THEN
        PERFORM Error(
            _NodeID    := _TokenNodeID,
            _ErrorType := _NodeType
        );
    END IF;

    PERFORM Log(
        _NodeID   := _TokenNodeID,
        _Severity := 'DEBUG5',
        _Message  := format('%s <- %s',
            Colorize(Node(_TokenNodeID, _Short := TRUE), 'CYAN'),
            Colorize(One_Line(_Literal), 'MAGENTA')
        ),
        _SaveDOTIR  := FALSE
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

SELECT COALESCE(array_to_string(array_agg(PrimitiveValue ORDER BY NodeID),''),'')
INTO STRICT _RecreatedSourceCode
FROM Nodes
WHERE ProgramID  = _ProgramID
AND BirthPhaseID = _PhaseID
AND NodeID       > _NodeID;

IF _RecreatedSourceCode IS DISTINCT FROM _SourceCode THEN
    RAISE EXCEPTION E'Unable to recreate source code for program "%" from created token nodes.\nSourceCode "%"\nIS DISTINCT FROM\nRecreatedSourceCode "%"',
        _Program,
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
