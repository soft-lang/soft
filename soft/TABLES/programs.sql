CREATE TABLE Programs (
ProgramID   serial    NOT NULL,
LanguageID  integer   NOT NULL REFERENCES Languages(LanguageID),
Program     text      NOT NULL,
PhaseID     integer   NOT NULL REFERENCES Phases(PhaseID),
Running     boolean   NOT NULL DEFAULT FALSE,
LogSeverity severity  NOT NULL DEFAULT 'NOTICE',
NodeID      integer,
Direction   direction NOT NULL DEFAULT 'ENTER',
PRIMARY KEY (ProgramID),
UNIQUE (LanguageID, Program)
);

CREATE UNIQUE INDEX ON Programs(ProgramID) WHERE Running IS TRUE;
