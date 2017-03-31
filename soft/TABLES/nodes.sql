CREATE TABLE Nodes (
NodeID               serial    NOT NULL,
ProgramID            integer   NOT NULL REFERENCES Programs(ProgramID),
NodeTypeID           integer   NOT NULL REFERENCES NodeTypes(NodeTypeID),
BirthPhaseID         integer   NOT NULL REFERENCES Phases(PhaseID),
VisitPhaseID         integer   NOT NULL REFERENCES Phases(PhaseID),
DeathPhaseID         integer            REFERENCES Phases(PhaseID),
TerminalType         regtype,
TerminalValue        text,
SourceCodeCharacters integer[],
PRIMARY KEY (NodeID),
CHECK (SourceCodeCharacters IS NULL OR (NULL <<>> ANY (SourceCodeCharacters)) IS FALSE),
CHECK ((TerminalType IS NULL) = (TerminalValue IS NULL)),
CHECK (BirthPhaseID <= VisitPhaseID),
CHECK (VisitPhaseID <= DeathPhaseID)
);
