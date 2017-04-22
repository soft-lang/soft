CREATE TABLE Phases (
PhaseID      serial   NOT NULL,
Phase        name     NOT NULL,
LanguageID   integer  NOT NULL REFERENCES Languages(LanguageID),
StopSeverity severity NOT NULL,
PRIMARY KEY (PhaseID)
);
