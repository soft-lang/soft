CREATE TABLE ErrorTypes (
ErrorTypeID         serial   NOT NULL,
ErrorType           text     NOT NULL,
LanguageID          integer  NOT NULL REFERENCES Languages(LanguageID),
Severity            severity NOT NULL,
PhaseID             integer           REFERENCES Phases(PhaseID),
NodeTypeID          integer           REFERENCES NodeTypes(NodeTypeID),
NodePattern         text,
Message             text,
Sigil               char,
ExpandedNodePattern text,
CHECK (length(Sigil) = 1),
PRIMARY KEY (ErrorTypeID),
CHECK (ErrorType ~ '^[A-Z_]+$'),
-- NodePattern is only used to define PARSER errors,
-- while PhaseID and NodeTypeID can be used to define
-- specific different error messages at certain phases/nodes
-- for one and the same ErrorType:
CHECK ((NodePattern IS NULL) OR (PhaseID IS NULL AND NodeTypeID IS NULL)),
UNIQUE (LanguageID, ErrorTypeID),
UNIQUE (LanguageID, ErrorType)
);
