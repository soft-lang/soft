CREATE TABLE Edges (
EdgeID           serial      NOT NULL,
ProgramID        integer     NOT NULL REFERENCES Programs(ProgramID),
ParentNodeID     integer     NOT NULL REFERENCES Nodes(NodeID),
ChildNodeID      integer     NOT NULL REFERENCES Nodes(NodeID),
BirthPhaseID     integer     NOT NULL REFERENCES Phases(PhaseID),
BirthTime        timestamptz NOT NULL DEFAULT clock_timestamp(),
DeathPhaseID     integer              REFERENCES Phases(PhaseID),
DeathTime        timestamptz,
PRIMARY KEY (EdgeID),
CHECK (ParentNodeID <> ChildNodeID),
CHECK (BirthPhaseID <= DeathPhaseID),
CHECK ((DeathPhaseID IS NULL) = (DeathTime IS NULL))
);
