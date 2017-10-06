CREATE VIEW Export_Node_Types AS
SELECT
Languages.Language,
NodeTypes.NodeType,
NodeTypes.PrimitiveType,
NodeTypes.NodeGroup,
NodeTypes.Literal,
NodeTypes.LiteralPattern,
NodeTypes.NodePattern,
Prologue.NodeType AS Prologue,
Epilogue.NodeType AS Epilogue,
GrowFrom.NodeType AS GrowFrom,
GrowInto.NodeType AS GrowInto,
NodeTypes.NodeSeverity,
NodeTypes.Precedence
FROM NodeTypes
INNER JOIN Languages             ON Languages.LanguageID = NodeTypes.LanguageID
LEFT  JOIN NodeTypes AS Prologue ON Prologue.NodeTypeID  = NodeTypes.PrologueNodeTypeID
LEFT  JOIN NodeTypes AS Epilogue ON Epilogue.NodeTypeID  = NodeTypes.EpilogueNodeTypeID
LEFT  JOIN NodeTypes AS GrowFrom ON GrowFrom.NodeTypeID  = NodeTypes.GrowFromNodeTypeID
LEFT  JOIN NodeTypes AS GrowInto ON GrowInto.NodeTypeID  = NodeTypes.GrowIntoNodeTypeID
ORDER BY NodeTypes.NodeTypeID
;
