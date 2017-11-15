CREATE TABLE DOTIR (
DOTIRID   serial      NOT NULL,
ProgramID integer     NOT NULL REFERENCES Programs(ProgramID),
PhaseID   integer     NOT NULL REFERENCES Phases(PhaseID),
Direction direction   NOT NULL,
NodeID    integer              REFERENCES Nodes(NodeID),
DOTIR     text        NOT NULL,
Logtime   timestamptz NOT NULL DEFAULT now(),
PRIMARY KEY (DOTIRID)
);

CREATE INDEX ON DOTIR (ProgramID, DOTIRID);
