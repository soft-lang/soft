CREATE TABLE Settings (
SettingID   serial   NOT NULL,
LogSeverity severity NOT NULL,
PRIMARY KEY (SettingID),
CHECK (SettingID = 1)
);

INSERT INTO Settings (LogSeverity) VALUES ('DEBUG3');
