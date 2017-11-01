CREATE TABLE Nodes (
NodeID             serial      NOT NULL,
ProgramID          integer     NOT NULL REFERENCES Programs(ProgramID),
EnvironmentID      integer     NOT NULL DEFAULT 0,
NodeTypeID         integer     NOT NULL REFERENCES NodeTypes(NodeTypeID),
Walkable           boolean     NOT NULL,
BirthPhaseID       integer     NOT NULL REFERENCES Phases(PhaseID),
BirthTime          timestamptz NOT NULL DEFAULT clock_timestamp(),
DeathPhaseID       integer              REFERENCES Phases(PhaseID),
DeathTime          timestamptz,
PrimitiveType      regtype,
PrimitiveValue     text,
ReferenceNodeID    integer              REFERENCES Nodes(NodeID),
ClonedFromNodeID   integer              REFERENCES Nodes(NodeID),
ClonedRootNodeID   integer              REFERENCES Nodes(NodeID),
PRIMARY KEY (NodeID),
CHECK (BirthPhaseID <= DeathPhaseID),
CHECK ((DeathPhaseID IS NULL) = (DeathTime IS NULL)),
CHECK ((ReferenceNodeID IS NULL) OR (PrimitiveType IS NULL AND PrimitiveValue IS NULL))
);

CREATE INDEX ON Nodes(ClonedRootNodeID) WHERE DeathPhaseID IS NULL;
CREATE INDEX ON Nodes(NodeTypeID) WHERE DeathPhaseID IS NULL;
CREATE INDEX ON Nodes(ProgramID) WHERE DeathPhaseID IS NULL;
CREATE INDEX ON Nodes(ProgramID,NodeTypeID) WHERE DeathPhaseID IS NULL;

ALTER TABLE Nodes ADD CONSTRAINT Nodes_Environment_FKey FOREIGN KEY (ProgramID, EnvironmentID) REFERENCES Environments (ProgramID, EnvironmentID);
