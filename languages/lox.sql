SET search_path TO soft, public, pg_temp;

\set ON_ERROR_STOP 1
\set language lox

BEGIN;

TRUNCATE TABLE Languages CASCADE;

SELECT New_Language(
    _Language                    := :'language',
    _VariableBinding             := 'CAPTURE_BY_REFERENCE',
    _ImplicitReturnValues        := TRUE,
    _StatementReturnValues       := TRUE,
    _ZeroBasedNumbering          := TRUE,
    _TruthyNonBooleans           := TRUE,
    _NilIfArrayOutOfBounds       := TRUE,
    _NilIfMissingHashKey         := TRUE,
    _StripZeroes                 := TRUE,
    _NegativeZeroes              := TRUE,
    _ReturnFromTopLevel          := FALSE,
    _ParametersOwnScope          := FALSE,
    _ClassInitializerName        := 'init',
    _MaxParameters               := 8
);

SELECT New_Phase(_Language := :'language', _Phase := 'TOKENIZE',      _StopSeverity := 'FATAL');
SELECT New_Phase(_Language := :'language', _Phase := 'EXTRACT_TESTS', _StopSeverity := 'FATAL');
SELECT New_Phase(_Language := :'language', _Phase := 'DISCARD',       _StopSeverity := 'FATAL');
SELECT New_Phase(_Language := :'language', _Phase := 'PARSE',         _StopSeverity := 'FATAL');
-- SELECT New_Phase(_Language := :'language', _Phase := 'PARSE_ERRORS');
SELECT New_Phase(_Language := :'language', _Phase := 'VALIDATE',      _StopSeverity := 'FATAL');
SELECT New_Phase(_Language := :'language', _Phase := 'REDUCE',        _StopSeverity := 'FATAL');
SELECT New_Phase(_Language := :'language', _Phase := 'MAP_VARIABLES', _StopSeverity := 'FATAL', _SaveDOTIR := TRUE);
SELECT New_Phase(_Language := :'language', _Phase := 'SHORT_CIRCUIT', _SaveDOTIR := TRUE);
SELECT New_Phase(_Language := :'language', _Phase := 'EVAL',          _SaveDOTIR := TRUE);

SELECT New_Built_In_Function(_Language := :'language', _Identifier := 'len',   _ImplementationFunction := 'LENGTH');
SELECT New_Built_In_Function(_Language := :'language', _Identifier := 'first', _ImplementationFunction := 'FIRST');
SELECT New_Built_In_Function(_Language := :'language', _Identifier := 'rest',  _ImplementationFunction := 'REST');
SELECT New_Built_In_Function(_Language := :'language', _Identifier := 'push',  _ImplementationFunction := 'PUSH');
SELECT New_Built_In_Function(_Language := :'language', _Identifier := 'last',  _ImplementationFunction := 'LAST');
SELECT New_Built_In_Function(_Language := :'language', _Identifier := 'puts',  _ImplementationFunction := 'PUTS');

-- Import NodeTypes:

CREATE TEMP TABLE ImportNodeTypes (
RowID          serial NOT NULL,
NodeType       text   NOT NULL,
PrimitiveType  text,
NodeGroup      text,
Precedence     text,
Literal        text,
LiteralPattern text,
NodePattern    text,
Prologue       text,
Epilogue       text,
GrowFrom       text,
GrowInto       text,
NodeSeverity   text,
PRIMARY KEY (RowID),
UNIQUE (NodeType)
);

\COPY ImportNodeTypes (NodeType, PrimitiveType, NodeGroup, Precedence, Literal, LiteralPattern, NodePattern, Prologue, Epilogue, GrowFrom, GrowInto, NodeSeverity) FROM node_types.csv WITH CSV HEADER QUOTE '"';

SELECT COUNT(*) FROM (
    SELECT New_Node_Type(
        _Language       := :'language',
        _NodeType       := NodeType,
        _PrimitiveType  := NULLIF(PrimitiveType,'')::regtype,
        _NodeGroup      := NULLIF(NodeGroup,''),
        _Precedence     := NULLIF(Precedence,''),
        _Literal        := NULLIF(Literal,''),
        _LiteralPattern := NULLIF(LiteralPattern,''),
        _NodePattern    := NULLIF(NodePattern,''),
        _Prologue       := NULLIF(Prologue,''),
        _Epilogue       := NULLIF(Epilogue,''),
        _GrowFrom       := NULLIF(GrowFrom,''),
        _GrowInto       := NULLIF(GrowInto,''),
        _NodeSeverity   := NULLIF(NodeSeverity,'')::severity
    ) FROM (SELECT * FROM ImportNodeTypes ORDER BY RowID) AS X
) AS Y;

SELECT COUNT(*) FROM (
    SELECT Valid_Node_Pattern(Languages.Language, NodeTypes.NodePattern)
    FROM NodeTypes
    INNER JOIN Languages ON Languages.LanguageID = NodeTypes.LanguageID
    AND NodeTypes.NodePattern IS NOT NULL
) AS X;

DROP TABLE ImportNodeTypes;

-- Normalize file since external editor might use quotes differently:
\COPY (SELECT * FROM View_Node_Types) TO node_types.csv WITH CSV HEADER QUOTE '"';

-- Import ErrorTypes:

CREATE TEMP TABLE ImportErrorTypes (
RowID          serial NOT NULL,
ErrorType      text   NOT NULL,
Severity       text   NOT NULL,
Phase          text,
NodeType       text,
NodePattern    text,
Message        text,
Sigil          char,
PRIMARY KEY (RowID),
UNIQUE (ErrorType)
);

\COPY ImportErrorTypes (ErrorType, Severity, Phase, NodeType, NodePattern, Message, Sigil) FROM error_types.csv WITH CSV HEADER QUOTE '"';

SELECT COUNT(*) FROM (
    SELECT New_Error_Type(
        _Language       := :'language',
        _ErrorType      := NULLIF(ErrorType,''),
        _Severity       := NULLIF(Severity,'')::severity,
        _Phase          := NULLIF(Phase,'')::name,
        _NodeType       := NULLIF(NodeType,''),
        _NodePattern    := NULLIF(NodePattern,''),
        _Message        := NULLIF(Message,''),
        _Sigil          := NULLIF(Sigil,'')
    ) FROM (SELECT * FROM ImportErrorTypes ORDER BY RowID) AS X
) AS Y;

DROP TABLE ImportErrorTypes;

-- Normalize file since external editor might use quotes differently:
\COPY (SELECT * FROM View_Error_Types) TO error_types.csv WITH CSV HEADER QUOTE '"';

\ir truthy-non-booleans.sql

\ir nil-input.sql

\ir :language/test.sql

COMMIT;
