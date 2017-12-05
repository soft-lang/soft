CREATE TABLE Tests (
TestID         serial  NOT NULL,
ProgramID      integer NOT NULL REFERENCES Programs(ProgramID),
ExpectedType   regtype,
ExpectedValue  text,
ExpectedTypes  regtype[],
ExpectedValues text[],
ExpectedError  text[],
ExpectedLog    text,
ExpectedSTDOUT text[],
StartedAt      timestamptz,
FinishedAt     timestamptz,
PRIMARY KEY (TestID)
);
