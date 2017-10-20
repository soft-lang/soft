SET search_path TO soft, public, pg_temp;

\set ON_ERROR_STOP 1
\set language lox

BEGIN;

TRUNCATE TABLE Languages CASCADE;

SELECT New_Language(
    _Language              := :'language',
    _VariableBinding       := 'CAPTURE_BY_REFERENCE',
    _ImplicitReturnValues  := TRUE,
    _StatementReturnValues := TRUE,
    _ZeroBasedNumbering    := TRUE,
    _TruthyNonBooleans     := TRUE,
    _NilIfArrayOutOfBounds := TRUE,
    _NilIfMissingHashKey   := TRUE
);

SELECT New_Phase(_Language := :'language', _Phase := 'TOKENIZE');
SELECT New_Phase(_Language := :'language', _Phase := 'DISCARD');
SELECT New_Phase(_Language := :'language', _Phase := 'PARSE');
SELECT New_Phase(_Language := :'language', _Phase := 'VALIDATE');
SELECT New_Phase(_Language := :'language', _Phase := 'REDUCE');
SELECT New_Phase(_Language := :'language', _Phase := 'MAP_VARIABLES', _SaveDOTIR := TRUE);
SELECT New_Phase(_Language := :'language', _Phase := 'SHORT_CIRCUIT', _SaveDOTIR := TRUE);
SELECT New_Phase(_Language := :'language', _Phase := 'EVAL',          _SaveDOTIR := TRUE);

SELECT New_Built_In_Function(_Language := :'language', _Identifier := 'len',   _ImplementationFunction := 'LENGTH');
SELECT New_Built_In_Function(_Language := :'language', _Identifier := 'first', _ImplementationFunction := 'FIRST');
SELECT New_Built_In_Function(_Language := :'language', _Identifier := 'rest',  _ImplementationFunction := 'REST');
SELECT New_Built_In_Function(_Language := :'language', _Identifier := 'push',  _ImplementationFunction := 'PUSH');
SELECT New_Built_In_Function(_Language := :'language', _Identifier := 'last',  _ImplementationFunction := 'LAST');
SELECT New_Built_In_Function(_Language := :'language', _Identifier := 'puts',  _ImplementationFunction := 'PUTS');

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

\ir truthy-non-booleans.sql

\ir nil-input.sql

CREATE OR REPLACE FUNCTION lox(
_SourceCode    text,
_LogSeverity   severity DEFAULT 'NOTICE',
_RunUntilPhase text     DEFAULT NULL
) RETURNS TABLE (
OK             boolean,
Error          text,
PrimitiveType  regtype,
PrimitiveValue text
)
LANGUAGE sql
AS $$
SELECT * FROM Soft(
    _Language      := 'lox',
    _SourceCode    := $1,
    _LogSeverity   := $2,
    _RunUntilPhase := $3
)
$$;

\ir :language/test.sql

COMMIT;
