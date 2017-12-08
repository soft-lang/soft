CREATE TABLE ErrorTypes (
ErrorTypeID         serial   NOT NULL,
ErrorType           text     NOT NULL,
LanguageID          integer  NOT NULL REFERENCES Languages(LanguageID),
Severity            severity NOT NULL,
Message             text,
Sigil               char,
CHECK (length(Sigil) = 1),
PRIMARY KEY (ErrorTypeID),
CHECK (ErrorType ~ '^[A-Z_]+$'),
UNIQUE (LanguageID, ErrorTypeID),
UNIQUE (LanguageID, ErrorType)
);
