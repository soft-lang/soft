CREATE TABLE soft.Programs (
ProgramID      serial  NOT NULL,
LanguageID     integer NOT NULL REFERENCES soft.Languages(LanguageID),
Program        text    NOT NULL,
NodeID         integer NOT NULL REFERENCES soft.Nodes(NodeID),
BonsaiSchemaID integer          REFERENCES soft.BonsaiSchemas(BonsaiSchemaID),
Running        boolean NOT NULL DEFAULT TRUE,
PRIMARY KEY (ProgramID),
UNIQUE (Program)
);

CREATE UNIQUE INDEX ON soft.Programs(ProgramID) WHERE Running IS TRUE;
