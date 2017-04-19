CREATE TABLE Tests (
TestID                serial  NOT NULL,
ProgramID             integer NOT NULL REFERENCES Programs(ProgramID),
TerminalType          regtype,
TerminalValue         text,
ExpectedTerminalType  regtype,
ExpectedTerminalValue text,
PRIMARY KEY (TestID)
);
