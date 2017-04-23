CREATE TABLE Nodes (
NodeID               serial    NOT NULL,
ProgramID            integer   NOT NULL REFERENCES Programs(ProgramID),
NodeTypeID           integer   NOT NULL REFERENCES NodeTypes(NodeTypeID),
BirthPhaseID         integer   NOT NULL REFERENCES Phases(PhaseID),
DeathPhaseID         integer            REFERENCES Phases(PhaseID),
TerminalType         regtype,
TerminalValue        text,
Visited              boolean[] NOT NULL DEFAULT ARRAY[FALSE],
ClonedFromNodeID     integer            REFERENCES Nodes(NodeID),
ClonedRootNodeID     integer            REFERENCES Nodes(NodeID),
PRIMARY KEY (NodeID),
CHECK (BirthPhaseID <= DeathPhaseID)
);
