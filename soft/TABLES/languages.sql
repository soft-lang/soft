CREATE TABLE Languages (
LanguageID                  serial          NOT NULL,
Language                    text            NOT NULL,
ImplicitReturnValues        boolean         NOT NULL,
StatementReturnValues       boolean         NOT NULL,
VariableBinding             variablebinding NOT NULL,
ZeroBasedNumbering          boolean         NOT NULL,
TruthyNonBooleans           boolean         NOT NULL,
NilIfArrayOutOfBounds       boolean         NOT NULL,
NilIfMissingHashKey         boolean         NOT NULL,
StripZeroes                 boolean         NOT NULL,
NegativeZeroes              boolean         NOT NULL,
ClassInitializerName        text,
Translation                 hstore,
PRIMARY KEY (LanguageID),
UNIQUE (Language)
);
