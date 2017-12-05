CREATE VIEW View_Tests AS
SELECT
Tests.TestID,
Programs.ProgramID,
Languages.Language,
Programs.Program,
Phases.Phase,
CASE
    WHEN Programs.DeathTime IS NULL THEN NULL
    WHEN Programs.Error IS NULL THEN
        CASE
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
            WHEN Tests.ExpectedSTDOUT IS NOT NULL AND array_to_string(Tests.ExpectedSTDOUT,E'\n') = COALESCE((
                SELECT string_agg(Log.Message, E'\n' ORDER BY Log.LogID)
                FROM Log
                WHERE Log.ProgramID = Tests.ProgramID
                AND   Log.Severity  = 'STDOUT'
            ),NULL::text)
            THEN TRUE
            ELSE FALSE
        END
    WHEN Programs.Error IS NOT NULL THEN
        CASE
            WHEN Tests.ExpectedError = Programs.Error THEN TRUE
            ELSE FALSE
        END
END AS OK,
(
    SELECT regexp_replace(Log.Message,'\x1b\[\d+m','','g')
    FROM Log
    WHERE Log.ProgramID = Programs.ProgramID
    ORDER BY Log.LogID DESC
    LIMIT 1
) AS Log,
Programs.Error
FROM Tests
INNER JOIN Programs        ON Programs.ProgramID   = Tests.ProgramID
INNER JOIN Languages       ON Languages.LanguageID = Programs.LanguageID
INNER JOIN Phases          ON Phases.PhaseID       = Programs.PhaseID
LEFT  JOIN Nodes           ON Nodes.NodeID         = Programs.NodeID
ORDER BY Programs.ProgramID
;
