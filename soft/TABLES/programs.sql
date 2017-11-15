CREATE TABLE Programs (
ProgramID       serial      NOT NULL,
LanguageID      integer     NOT NULL REFERENCES Languages(LanguageID),
Program         text        NOT NULL,
PhaseID         integer     NOT NULL REFERENCES Phases(PhaseID),
LogSeverity     severity    NOT NULL DEFAULT 'NOTICE',
Iterations      bigint      NOT NULL DEFAULT 0,
BirthTime       timestamptz NOT NULL DEFAULT clock_timestamp(),
RunAt           timestamptz,
DeathTime       timestamptz,
NodeID          integer,
Direction       direction   NOT NULL DEFAULT 'ENTER',
RunUntilPhaseID integer     REFERENCES Phases(PhaseID),
MaxIterations   bigint,
PRIMARY KEY (ProgramID),
UNIQUE (LanguageID, Program),
CHECK (PhaseID    <= RunUntilPhaseID),
CHECK (Iterations <= MaxIterations)
);
