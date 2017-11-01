CREATE TABLE Environments (
ProgramID     integer NOT NULL REFERENCES Programs(ProgramID),
EnvironmentID integer NOT NULL,
PRIMARY KEY (ProgramID, EnvironmentID)
);
