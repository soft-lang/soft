CREATE TABLE Tests (
TestID        serial  NOT NULL,
ProgramID     integer NOT NULL REFERENCES Programs(ProgramID),
ExpectedType  regtype,
ExpectedValue text,
ExpectedError text,
ExpectedLog   text,
PRIMARY KEY (TestID)
);
