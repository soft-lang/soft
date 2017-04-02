CREATE TABLE Languages (
LanguageID  serial   NOT NULL,
Language    text     NOT NULL,
LogSeverity severity NOT NULL,
PRIMARY KEY (LanguageID),
UNIQUE (Language)
);
