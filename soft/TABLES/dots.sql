CREATE TABLE DOTs (
DOTID     serial      NOT NULL,
ProgramID integer     NOT NULL REFERENCES Programs(ProgramID),
PhaseID   integer     NOT NULL REFERENCES Phases(PhaseID),
DOT       text        NOT NULL,
Logtime   timestamptz NOT NULL DEFAULT now(),
PRIMARY KEY (DOTID)
);
