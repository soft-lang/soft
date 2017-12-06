CREATE VIEW View_Programs AS
SELECT
Programs.ProgramID,
Languages.Language,
Programs.Program,
Phases.Phase,
Programs.LogSeverity,
Node(Nodes.NodeID),
Programs.Direction
FROM Programs
INNER JOIN Languages       ON Languages.LanguageID = Programs.LanguageID
INNER JOIN Phases          ON Phases.PhaseID       = Programs.PhaseID
LEFT  JOIN Nodes           ON Nodes.NodeID         = Programs.NodeID
ORDER BY Programs.ProgramID
;
