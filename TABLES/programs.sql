CREATE TABLE soft.Programs (
ProgramID  serial      NOT NULL,
LanguageID integer     NOT NULL REFERENCES soft.Languages(LanguageID),
Program    text        NOT NULL,
NodeID     integer     NOT NULL REFERENCES soft.Nodes(NodeID),
PRIMARY KEY (ProgramID),
UNIQUE (Program)
);
