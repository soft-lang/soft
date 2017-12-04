CREATE TABLE Environments (
ProgramID     integer NOT NULL REFERENCES Programs(ProgramID),
EnvironmentID integer NOT NULL,
ScopeNodeID   integer,
PRIMARY KEY (ProgramID, EnvironmentID)
);
