CREATE TABLE BuiltInFunctions (
BuiltInFunctionID      serial  NOT NULL,
LanguageID             integer NOT NULL REFERENCES Languages(LanguageID),
Identifier             text    NOT NULL,
ImplementationFunction text    NOT NULL,
PRIMARY KEY (BuiltInFunctionID),
CHECK (ImplementationFunction ~ '^[A-Z_]+$'),
UNIQUE (LanguageID, Identifier)
);
