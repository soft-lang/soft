CREATE VIEW View_Nodes AS
SELECT
Nodes.NodeID,
Node(Nodes.NodeID),
Nodes.Environment,
Programs.Program,
Languages.Language,
NodeTypes.NodeType,
Nodes.Walkable,
Birth.Phase AS BirthPhase,
Death.Phase AS DeathPhase,
Nodes.PrimitiveType,
Nodes.PrimitiveValue,
Node(ReferenceNodeID) AS ReferenceNode,
Node(ClonedFromNodeID) AS ClonedFromNode,
Node(ClonedRootNodeID) AS ClonedRootNode
FROM Nodes
INNER JOIN NodeTypes       ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
INNER JOIN Programs        ON Programs.ProgramID   = Nodes.ProgramID
INNER JOIN Languages       ON Languages.LanguageID = Programs.LanguageID
INNER JOIN Phases AS Birth ON Birth.PhaseID        = Nodes.BirthPhaseID
LEFT  JOIN Phases AS Death ON Death.PhaseID        = Nodes.DeathPhaseID
ORDER BY Nodes.NodeID
;
