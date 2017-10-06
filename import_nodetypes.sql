SET search_path TO soft, public, pg_temp;

TRUNCATE NodeTypes, Nodes, Programs, Edges, Log, Tests;

CREATE TEMP TABLE ImportNodeTypes (
RowID          serial NOT NULL,
Language       text   NOT NULL,
NodeType       text   NOT NULL,
PrimitiveType  text,
NodeGroup      text,
Literal        text,
LiteralPattern text,
NodePattern    text,
Prologue       text,
Epilogue       text,
GrowFrom       text,
GrowInto       text,
NodeSeverity   text,
Precedence     text,
PRIMARY KEY (RowID),
UNIQUE (Language, NodeType)
);

\COPY ImportNodeTypes (Language, NodeType, PrimitiveType, NodeGroup, Literal, LiteralPattern, NodePattern, Prologue, Epilogue, GrowFrom, GrowInto, NodeSeverity, Precedence) FROM ~/src/soft/languages/monkey/node_types.csv WITH CSV HEADER QUOTE '"';

SELECT COUNT(*) FROM (
	SELECT New_Node_Type(
		_Language       := Language,
		_NodeType       := NodeType,
		_PrimitiveType  := NULLIF(PrimitiveType,'')::regtype,
		_NodeGroup      := NULLIF(NodeGroup,''),
		_Literal        := NULLIF(Literal,''),
		_LiteralPattern := NULLIF(LiteralPattern,''),
		_NodePattern    := NULLIF(NodePattern,''),
		_Prologue       := NULLIF(Prologue,''),
		_Epilogue       := NULLIF(Epilogue,''),
		_GrowFrom       := NULLIF(GrowFrom,''),
		_GrowInto       := NULLIF(GrowInto,''),
		_NodeSeverity   := NULLIF(NodeSeverity,'')::severity,
		_Precedence     := NULLIF(Precedence,'')::integer
	) FROM (SELECT * FROM ImportNodeTypes ORDER BY RowID) AS X
) AS Y;

DROP TABLE ImportNodeTypes;
