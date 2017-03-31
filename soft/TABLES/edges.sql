CREATE TABLE Edges (
EdgeID        serial    NOT NULL,
ProgramID     integer   NOT NULL REFERENCES Programs(ProgramID),
ParentNodeID  integer   NOT NULL REFERENCES Nodes(NodeID),
ChildNodeID   integer   NOT NULL REFERENCES Nodes(NodeID),
BirthPhaseID  integer   NOT NULL REFERENCES Phases(PhaseID),
ExistPhaseID  integer   NOT NULL REFERENCES Phases(PhaseID),
DeathPhaseID  integer            REFERENCES Phases(PhaseID),
PRIMARY KEY (EdgeID),
CHECK (ParentNodeID <> ChildNodeID),
CHECK (BirthPhaseID <= ExistPhaseID),
CHECK (ExistPhaseID <= DeathPhaseID)
);
