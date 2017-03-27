CREATE TABLE soft.BonsaiSchemas (
BonsaiSchemaID serial  NOT NULL,
LanguageID     integer NOT NULL REFERENCES soft.Languages(LanguageID),
BonsaiSchema   name    NOT NULL,
PRIMARY KEY (BonsaiSchemaID),
UNIQUE (LanguageID, BonsaiSchema)
);
