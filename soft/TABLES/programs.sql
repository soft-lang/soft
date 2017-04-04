CREATE TABLE Programs (
ProgramID  serial  NOT NULL,
Program    text    NOT NULL,
PhaseID    integer NOT NULL REFERENCES Phases(PhaseID),
Running    boolean NOT NULL DEFAULT FALSE,
NodeID     integer,
PRIMARY KEY (ProgramID),
UNIQUE (Program)
);

CREATE UNIQUE INDEX ON Programs(ProgramID) WHERE Running IS TRUE;
