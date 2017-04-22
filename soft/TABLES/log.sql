CREATE TABLE Log (
LogID                serial      NOT NULL,
ProgramID            integer     NOT NULL REFERENCES Programs(ProgramID),
NodeID               integer     NOT NULL REFERENCES Nodes(NodeID),
PhaseID              integer     NOT NULL REFERENCES Phases(PhaseID),
Severity             severity    NOT NULL,
Message              text        NOT NULL,
Logtime              timestamptz NOT NULL DEFAULT now(),
SourceCodeCharacters integer[],
NodeIDs              integer[],
PRIMARY KEY (LogID)
);
