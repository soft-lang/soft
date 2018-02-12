CREATE TABLE LLVMIR (
ProgramID integer NOT NULL REFERENCES Programs(ProgramID),
LLVMIR    text    NOT NULL,
PRIMARY KEY (ProgramID)
);
