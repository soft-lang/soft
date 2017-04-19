CREATE TABLE Languages (
LanguageID            serial   NOT NULL,
Language              text     NOT NULL,
LogSeverity           severity NOT NULL,
ImplicitReturnValues  boolean  NOT NULL,
StatementReturnValues boolean NOT NULL,
PRIMARY KEY (LanguageID),
UNIQUE (Language)
);
