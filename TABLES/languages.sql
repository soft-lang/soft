CREATE TABLE soft.Languages (
LanguageID serial NOT NULL,
Language   text   NOT NULL,
PRIMARY KEY (LanguageID),
UNIQUE (Language)
);
