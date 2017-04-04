CREATE TABLE Nodes (
NodeID               serial    NOT NULL,
ProgramID            integer   NOT NULL REFERENCES Programs(ProgramID),
NodeTypeID           integer   NOT NULL REFERENCES NodeTypes(NodeTypeID),
BirthPhaseID         integer   NOT NULL REFERENCES Phases(PhaseID),
EnterPhaseID         integer            REFERENCES Phases(PhaseID),
LeavePhaseID         integer            REFERENCES Phases(PhaseID),
DeathPhaseID         integer            REFERENCES Phases(PhaseID),
TerminalType         regtype,
TerminalValue        text,
SourceCodeCharacters integer[],
PRIMARY KEY (NodeID),
CHECK (SourceCodeCharacters IS NULL OR (NULL <<>> ANY (SourceCodeCharacters)) IS FALSE),
CHECK (BirthPhaseID <= EnterPhaseID),
CHECK (BirthPhaseID <= LeavePhaseID),
CHECK (EnterPhaseID <= DeathPhaseID),
CHECK (LeavePhaseID <= DeathPhaseID)
);
