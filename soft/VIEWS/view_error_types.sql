CREATE VIEW View_Error_Types AS
SELECT * FROM (
    SELECT
    ErrorTypes.ErrorType,
    ErrorTypes.Severity,
    Phases.Phase,
    NodeTypes.NodeType,
    ErrorTypes.NodePattern,
    ErrorTypes.Message,
    ErrorTypes.Sigil
    FROM ErrorTypes
    INNER JOIN Languages ON Languages.LanguageID = ErrorTypes.LanguageID
    LEFT  JOIN NodeTypes ON NodeTypes.NodeTypeID = ErrorTypes.NodeTypeID
    LEFT  JOIN Phases    ON Phases.PhaseID       = ErrorTypes.PhaseID
    WHERE ErrorTypes.NodePattern IS NOT NULL
    -- The order of ErrorTypes with NodePatterns matter:
    ORDER BY ErrorTypes.ErrorTypeID
) AS ParserErrors
UNION ALL
SELECT * FROM (
    SELECT
    ErrorTypes.ErrorType,
    ErrorTypes.Severity,
    Phases.Phase,
    NodeTypes.NodeType,
    ErrorTypes.NodePattern,
    ErrorTypes.Message,
    ErrorTypes.Sigil
    FROM ErrorTypes
    INNER JOIN Languages ON Languages.LanguageID = ErrorTypes.LanguageID
    LEFT  JOIN NodeTypes ON NodeTypes.NodeTypeID = ErrorTypes.NodeTypeID
    LEFT  JOIN Phases    ON Phases.PhaseID       = ErrorTypes.PhaseID
    WHERE ErrorTypes.NodePattern IS NULL
    -- The order of ErrorTypes without NodePattern doesn't matter,
    -- so sort by ErrorType to make diffing between languages easier:
    ORDER BY ErrorTypes.ErrorType
) AS RunTimeErrors
;