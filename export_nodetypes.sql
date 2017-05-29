SET search_path TO soft;

CREATE TEMP VIEW vNodeTypes AS
SELECT
NodeTypes.NodeTypeID,
Languages.Language,
NodeTypes.NodeType,
NodeTypes.TerminalType::text,
NodeTypes.NodeGroup,
NodeTypes.Literal,
regexp_replace(NodeTypes.LiteralPattern, '^\^\((.*)\)$', '\1') AS LiteralPattern,
NodeTypes.NodePattern,
Prologue.NodeType AS Prologue,
Epilogue.NodeType AS Epilogue,
GrowFrom.NodeType AS GrowFrom,
GrowInto.NodeType AS GrowInto,
NodeTypes.NodeSeverity
FROM NodeTypes
INNER JOIN Languages ON Languages.LanguageID = NodeTypes.LanguageID
LEFT JOIN NodeTypes AS Prologue ON Prologue.NodeTypeID = NodeTypes.PrologueNodeTypeID
LEFT JOIN NodeTypes AS Epilogue ON Epilogue.NodeTypeID = NodeTypes.EpilogueNodeTypeID
LEFT JOIN NodeTypes AS GrowFrom ON GrowFrom.NodeTypeID = NodeTypes.GrowFromNodeTypeID
LEFT JOIN NodeTypes AS GrowInto ON GrowInto.NodeTypeID = NodeTypes.GrowIntoNodeTypeID
;

\COPY (SELECT * FROM vNodeTypes ORDER BY NodeTypeID) TO ~/src/soft/languages/monkey/node_types.csv WITH CSV HEADER;
