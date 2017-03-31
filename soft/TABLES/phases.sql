CREATE TABLE Phases (
PhaseID    serial  NOT NULL,
Phase      name    NOT NULL,
LanguageID integer NOT NULL REFERENCES Languages(LanguageID),
PRIMARY KEY (PhaseID),
UNIQUE (LanguageID, Phase)
);
