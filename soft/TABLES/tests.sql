CREATE TABLE Tests (
TestID        serial  NOT NULL,
ProgramID     integer NOT NULL REFERENCES Programs(ProgramID),
TerminalType  regtype,
TerminalValue text,
ExpectedType  regtype,
ExpectedValue text,
PRIMARY KEY (TestID)
);
