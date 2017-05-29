SET search_path TO soft, public, pg_temp;

TRUNCATE NodeTypes, Nodes, Programs, Edges, Log, Tests;

CREATE TEMP TABLE ImportNodeTypes (
RowID          serial NOT NULL,
NodeTypeID     text,
Language       text   NOT NULL,
NodeType       text   NOT NULL,
TerminalType   text,
NodeGroup      text,
Literal        text,
LiteralPattern text,
NodePattern    text,
Prologue       text,
Epilogue       text,
GrowFrom       text,
GrowInto       text,
NodeSeverity   text,
PRIMARY KEY (RowID),
UNIQUE (Language, NodeType)
);

\COPY ImportNodeTypes (NodeTypeID, Language, NodeType, TerminalType, NodeGroup, Literal, LiteralPattern, NodePattern, Prologue, Epilogue, GrowFrom, GrowInto, NodeSeverity) FROM ~/src/soft/languages/monkey/node_types.csv WITH CSV HEADER QUOTE '"';

SELECT COUNT(*) FROM (
	SELECT New_Node_Type(
		_Language       := Language,
		_NodeType       := NodeType,
		_TerminalType   := NULLIF(TerminalType,'')::regtype,
		_NodeGroup      := NULLIF(NodeGroup,''),
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

DROP TABLE ImportNodeTypes;
