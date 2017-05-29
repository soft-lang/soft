CREATE TABLE Nodes (
NodeID               serial      NOT NULL,
ProgramID            integer     NOT NULL REFERENCES Programs(ProgramID),
NodeTypeID           integer     NOT NULL REFERENCES NodeTypes(NodeTypeID),
Walkable             boolean     NOT NULL,
BirthPhaseID         integer     NOT NULL REFERENCES Phases(PhaseID),
BirthTime            timestamptz NOT NULL DEFAULT clock_timestamp(),
DeathPhaseID         integer            REFERENCES Phases(PhaseID),
DeathTime            timestamptz,
TerminalType         regtype,
TerminalValue        text,
ClonedFromNodeID     integer            REFERENCES Nodes(NodeID),
ClonedRootNodeID     integer            REFERENCES Nodes(NodeID),
PRIMARY KEY (NodeID),
CHECK (BirthPhaseID <= DeathPhaseID),
CHECK ((DeathPhaseID IS NULL) = (DeathTime IS NULL))
);
