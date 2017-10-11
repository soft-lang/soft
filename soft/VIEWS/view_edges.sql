CREATE VIEW View_Edges AS
SELECT
Edges.EdgeID,
Programs.Program,
Languages.Language,
Edges.ParentNodeID,
Edges.ChildNodeID,
Birth.Phase AS BirthPhase,
Death.Phase AS DeathPhase,
format('%s -> %s', Node(Edges.ParentNodeID), Node(Edges.ChildNodeID)) AS Edge
FROM Edges
INNER JOIN Programs        ON Programs.ProgramID   = Edges.ProgramID
INNER JOIN Languages       ON Languages.LanguageID = Programs.LanguageID
INNER JOIN Phases AS Birth ON Birth.PhaseID        = Edges.BirthPhaseID
LEFT  JOIN Phases AS Death ON Death.PhaseID        = Edges.DeathPhaseID
ORDER BY Edges.EdgeID
;
