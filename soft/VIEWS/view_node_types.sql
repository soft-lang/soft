CREATE VIEW View_Node_Types AS
SELECT * FROM (
    SELECT
    Languages.Language,
    NodeTypes.NodeType,
    NodeTypes.PrimitiveType,
    NodeTypes.NodeGroup,
    NodeTypes.Precedence,
    NodeTypes.Literal,
    NodeTypes.LiteralPattern,
    NodeTypes.NodePattern,
    Prologue.NodeType AS Prologue,
    Epilogue.NodeType AS Epilogue,
    GrowFrom.NodeType AS GrowFrom,
    GrowInto.NodeType AS GrowInto,
    NodeTypes.NodeSeverity
    FROM NodeTypes
    INNER JOIN Languages             ON Languages.LanguageID = NodeTypes.LanguageID
    LEFT  JOIN NodeTypes AS Prologue ON Prologue.NodeTypeID  = NodeTypes.PrologueNodeTypeID
    LEFT  JOIN NodeTypes AS Epilogue ON Epilogue.NodeTypeID  = NodeTypes.EpilogueNodeTypeID
    LEFT  JOIN NodeTypes AS GrowFrom ON GrowFrom.NodeTypeID  = NodeTypes.GrowFromNodeTypeID
    LEFT  JOIN NodeTypes AS GrowInto ON GrowInto.NodeTypeID  = NodeTypes.GrowIntoNodeTypeID
    WHERE NodeTypes.Literal        IS NULL
    AND   NodeTypes.LiteralPattern IS NULL
    AND   NodeTypes.NodePattern    IS NULL
    ORDER BY Languages.Language, NodeTypes.NodeGroup, NodeTypes.NodeType
) AS NULLs
UNION ALL
SELECT * FROM (
    SELECT
    Languages.Language,
    NodeTypes.NodeType,
    NodeTypes.PrimitiveType,
    NodeTypes.NodeGroup,
    NodeTypes.Precedence,
    NodeTypes.Literal,
    NodeTypes.LiteralPattern,
    NodeTypes.NodePattern,
    Prologue.NodeType AS Prologue,
    Epilogue.NodeType AS Epilogue,
    GrowFrom.NodeType AS GrowFrom,
    GrowInto.NodeType AS GrowInto,
    NodeTypes.NodeSeverity
    FROM NodeTypes
    INNER JOIN Languages             ON Languages.LanguageID = NodeTypes.LanguageID
    LEFT  JOIN NodeTypes AS Prologue ON Prologue.NodeTypeID  = NodeTypes.PrologueNodeTypeID
    LEFT  JOIN NodeTypes AS Epilogue ON Epilogue.NodeTypeID  = NodeTypes.EpilogueNodeTypeID
    LEFT  JOIN NodeTypes AS GrowFrom ON GrowFrom.NodeTypeID  = NodeTypes.GrowFromNodeTypeID
    LEFT  JOIN NodeTypes AS GrowInto ON GrowInto.NodeTypeID  = NodeTypes.GrowIntoNodeTypeID
    WHERE NodeTypes.Literal IS NOT NULL
    ORDER BY Languages.Language, NodeTypes.LiteralLength DESC, NodeTypes.NodeGroup, NodeTypes.Literal
) AS Literals
UNION ALL
SELECT * FROM (
    SELECT
    Languages.Language,
    NodeTypes.NodeType,
    NodeTypes.PrimitiveType,
    NodeTypes.NodeGroup,
    NodeTypes.Precedence,
    NodeTypes.Literal,
    NodeTypes.LiteralPattern,
    NodeTypes.NodePattern,
    Prologue.NodeType AS Prologue,
    Epilogue.NodeType AS Epilogue,
    GrowFrom.NodeType AS GrowFrom,
    GrowInto.NodeType AS GrowInto,
    NodeTypes.NodeSeverity
    FROM NodeTypes
    INNER JOIN Languages             ON Languages.LanguageID = NodeTypes.LanguageID
    LEFT  JOIN NodeTypes AS Prologue ON Prologue.NodeTypeID  = NodeTypes.PrologueNodeTypeID
    LEFT  JOIN NodeTypes AS Epilogue ON Epilogue.NodeTypeID  = NodeTypes.EpilogueNodeTypeID
    LEFT  JOIN NodeTypes AS GrowFrom ON GrowFrom.NodeTypeID  = NodeTypes.GrowFromNodeTypeID
    LEFT  JOIN NodeTypes AS GrowInto ON GrowInto.NodeTypeID  = NodeTypes.GrowIntoNodeTypeID
    WHERE NodeTypes.LiteralPattern IS NOT NULL
    ORDER BY Languages.Language, Precedence(NodeTypes.NodeTypeID), NodeTypes.NodeGroup, NodeTypes.NodeType
) AS LiteralPatterns
UNION ALL
SELECT * FROM (
    SELECT
    Languages.Language,
    NodeTypes.NodeType,
    NodeTypes.PrimitiveType,
    NodeTypes.NodeGroup,
    NodeTypes.Precedence,
    NodeTypes.Literal,
    NodeTypes.LiteralPattern,
    NodeTypes.NodePattern,
    Prologue.NodeType AS Prologue,
    Epilogue.NodeType AS Epilogue,
    GrowFrom.NodeType AS GrowFrom,
    GrowInto.NodeType AS GrowInto,
    NodeTypes.NodeSeverity
    FROM NodeTypes
    INNER JOIN Languages             ON Languages.LanguageID = NodeTypes.LanguageID
    LEFT  JOIN NodeTypes AS Prologue ON Prologue.NodeTypeID  = NodeTypes.PrologueNodeTypeID
    LEFT  JOIN NodeTypes AS Epilogue ON Epilogue.NodeTypeID  = NodeTypes.EpilogueNodeTypeID
    LEFT  JOIN NodeTypes AS GrowFrom ON GrowFrom.NodeTypeID  = NodeTypes.GrowFromNodeTypeID
    LEFT  JOIN NodeTypes AS GrowInto ON GrowInto.NodeTypeID  = NodeTypes.GrowIntoNodeTypeID
    WHERE NodeTypes.NodePattern IS NOT NULL
    ORDER BY Languages.Language, Precedence(NodeTypes.NodeTypeID), NodeTypes.NodeGroup, NodeTypes.NodeType
) AS NodePatterns
;