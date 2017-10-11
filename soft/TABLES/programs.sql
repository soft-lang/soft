CREATE TABLE Programs (
ProgramID   serial    NOT NULL,
LanguageID  integer   NOT NULL REFERENCES Languages(LanguageID),
Program     text      NOT NULL,
PhaseID     integer   NOT NULL REFERENCES Phases(PhaseID),
LogSeverity severity  NOT NULL DEFAULT 'NOTICE',
NodeID      integer,
Direction   direction NOT NULL DEFAULT 'ENTER',
PRIMARY KEY (ProgramID),
UNIQUE (LanguageID, Program)
);
