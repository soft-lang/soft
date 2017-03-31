CREATE TABLE Edges (
EdgeID        serial    NOT NULL,
ProgramID     integer   NOT NULL REFERENCES Programs(ProgramID),
ParentNodeID  integer   NOT NULL REFERENCES Nodes(NodeID),
ChildNodeID   integer   NOT NULL REFERENCES Nodes(NodeID),
BirthPhaseID  integer   NOT NULL REFERENCES Phases(PhaseID),
VisitPhaseID  integer   NOT NULL REFERENCES Phases(PhaseID),
DeathPhaseID  integer            REFERENCES Phases(PhaseID),
PRIMARY KEY (EdgeID),
CHECK (ParentNodeID <> ChildNodeID),
CHECK (BirthPhaseID <= VisitPhaseID),
CHECK (VisitPhaseID <= DeathPhaseID)
);