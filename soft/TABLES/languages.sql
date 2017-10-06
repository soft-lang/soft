CREATE TABLE Languages (
LanguageID            serial          NOT NULL,
Language              text            NOT NULL,
LogSeverity           severity        NOT NULL,
ImplicitReturnValues  boolean         NOT NULL,
StatementReturnValues boolean         NOT NULL,
VariableBinding       variablebinding NOT NULL,
ZeroBasedNumbering    boolean         NOT NULL,
TruthyNonBooleans     boolean         NOT NULL,
ArrayOutOfBoundsError boolean         NOT NULL,
MissingHashKeyError   boolean         NOT NULL,
PRIMARY KEY (LanguageID),
UNIQUE (Language)
);
