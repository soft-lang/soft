CREATE VIEW View_Tests AS
SELECT
Tests.TestID,
Programs.ProgramID,
Languages.Language,
RIGHT(Programs.Program,30) AS Program,
Phases.Phase,
CASE
    WHEN Programs.DeathTime IS NULL THEN NULL
    WHEN Tests.ExpectedType  = Programs.ResultType  AND Tests.ExpectedValue  = Programs.ResultValue  THEN TRUE
    WHEN Tests.ExpectedTypes = Programs.ResultTypes AND Tests.ExpectedValues = Programs.ResultValues THEN TRUE
    WHEN Tests.ExpectedLog IS NOT NULL AND EXISTS (
        SELECT 1
        FROM Log
        INNER JOIN Phases    ON Phases.PhaseID       = Log.PhaseID
        INNER JOIN Nodes     ON Nodes.NodeID         = Log.NodeID
        INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
        WHERE Log.ProgramID = Tests.ProgramID
        AND format('%s %s %s',
            Phases.Phase,
            Log.Severity::text,
            NodeTypes.NodeType
        ) = Tests.ExpectedLog
    )
    THEN TRUE
    WHEN Tests.ExpectedSTDOUT IS NOT NULL AND array_to_string(Tests.ExpectedSTDOUT,E'\n') = (
        SELECT string_agg(Log.Message, E'\n' ORDER BY Log.LogID)
        FROM Log
        WHERE Log.ProgramID = Tests.ProgramID
        AND   Log.Severity  = 'STDOUT'
        AND   Log.Message IS NOT NULL
    )
    THEN TRUE
    WHEN Tests.ExpectedError IS NOT NULL AND array_to_string(Tests.ExpectedError,E'\n') = (
        SELECT string_agg(Log.Message, E'\n' ORDER BY Log.LogID)
        FROM Log
        WHERE Log.ProgramID = Tests.ProgramID
        AND   Log.Severity  = 'ERROR'
        AND   Log.Message IS NOT NULL
    )
    THEN TRUE
    ELSE FALSE
END AS OK,
(
    SELECT Strip_ANSI(Log.Message)
    FROM Log
    WHERE Log.ProgramID = Programs.ProgramID
    ORDER BY Log.LogID DESC
    LIMIT 1
) AS LastLog,
Tests.ExpectedSTDOUT,
(
    SELECT string_agg(Log.Message, E'\n' ORDER BY Log.LogID)
    FROM Log
    WHERE Log.ProgramID = Tests.ProgramID
    AND   Log.Severity  = 'STDOUT'
    AND   Log.Message IS NOT NULL
) AS STDOUT,
(
    SELECT Log.ErrorType
    FROM Log
    WHERE Log.ProgramID = Programs.ProgramID
    AND Log.ErrorType IS NOT NULL
    ORDER BY Log.LogID DESC
    LIMIT 1
) AS LastErrorType,
(
    SELECT Log.ErrorInfo
    FROM Log
    WHERE Log.ProgramID = Programs.ProgramID
    AND Log.ErrorInfo IS NOT NULL
    ORDER BY Log.LogID DESC
    LIMIT 1
) AS LastErrorInfo,
Tests.ExpectedError,
(
    SELECT string_agg(Log.Message, E'\n' ORDER BY Log.LogID)
    FROM Log
    WHERE Log.ProgramID = Tests.ProgramID
    AND   Log.Severity  = 'ERROR'
    AND   Log.Message IS NOT NULL
) AS Error
FROM Tests
INNER JOIN Programs        ON Programs.ProgramID   = Tests.ProgramID
INNER JOIN Languages       ON Languages.LanguageID = Programs.LanguageID
INNER JOIN Phases          ON Phases.PhaseID       = Programs.PhaseID
LEFT  JOIN Nodes           ON Nodes.NodeID         = Programs.NodeID
ORDER BY Programs.ProgramID
;
