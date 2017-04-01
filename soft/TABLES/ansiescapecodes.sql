CREATE TABLE ANSIEscapeCodes (
ANSIEscapeCodeID serial NOT NULL,
Name             text   NOT NULL,
EscapeSequence   text   NOT NULL,
PRIMARY KEY (ANSIEscapeCodeID),
UNIQUE (Name),
UNIQUE (EscapeSequence)
);

INSERT INTO ANSIEscapeCodes (Name, EscapeSequence) VALUES ('RESET',      E'\x1b[0m');
INSERT INTO ANSIEscapeCodes (Name, EscapeSequence) VALUES ('BOLD',       E'\x1b[1m');
INSERT INTO ANSIEscapeCodes (Name, EscapeSequence) VALUES ('BLACK',      E'\x1b[30m');
INSERT INTO ANSIEscapeCodes (Name, EscapeSequence) VALUES ('RED',        E'\x1b[31m');
INSERT INTO ANSIEscapeCodes (Name, EscapeSequence) VALUES ('GREEN',      E'\x1b[32m');
INSERT INTO ANSIEscapeCodes (Name, EscapeSequence) VALUES ('YELLOW',     E'\x1b[33m');
INSERT INTO ANSIEscapeCodes (Name, EscapeSequence) VALUES ('BLUE',       E'\x1b[34m');
INSERT INTO ANSIEscapeCodes (Name, EscapeSequence) VALUES ('MAGENTA',    E'\x1b[35m');
INSERT INTO ANSIEscapeCodes (Name, EscapeSequence) VALUES ('CYAN',       E'\x1b[36m');
INSERT INTO ANSIEscapeCodes (Name, EscapeSequence) VALUES ('WHITE',      E'\x1b[37m');
INSERT INTO ANSIEscapeCodes (Name, EscapeSequence) VALUES ('BG_BLACK',   E'\x1b[40m');
INSERT INTO ANSIEscapeCodes (Name, EscapeSequence) VALUES ('BG_RED',     E'\x1b[41m');
INSERT INTO ANSIEscapeCodes (Name, EscapeSequence) VALUES ('BG_GREEN',   E'\x1b[42m');
INSERT INTO ANSIEscapeCodes (Name, EscapeSequence) VALUES ('BG_YELLOW',  E'\x1b[43m');
INSERT INTO ANSIEscapeCodes (Name, EscapeSequence) VALUES ('BG_BLUE',    E'\x1b[44m');
INSERT INTO ANSIEscapeCodes (Name, EscapeSequence) VALUES ('BG_MAGENTA', E'\x1b[45m');
INSERT INTO ANSIEscapeCodes (Name, EscapeSequence) VALUES ('BG_CYAN',    E'\x1b[46m');
INSERT INTO ANSIEscapeCodes (Name, EscapeSequence) VALUES ('BG_WHITE',   E'\x1b[47m');
