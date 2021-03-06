CREATE OR REPLACE FUNCTION New_Phase(
_Language     text,
_Phase        text,
_StopSeverity severity DEFAULT 'ERROR',
_SaveDOTIR    boolean  DEFAULT FALSE
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_LanguageID integer;
_PhaseID    integer;
BEGIN
SELECT LanguageID INTO STRICT _LanguageID FROM Languages WHERE Language = _Language;

IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_namespace WHERE nspname = _Phase) THEN
    RAISE EXCEPTION 'Schema for phase "%" does not exist.', _Phase;
END IF;

INSERT INTO Phases ( LanguageID,  Phase,  StopSeverity,  SaveDOTIR)
VALUES             (_LanguageID, _Phase, _StopSeverity, _SaveDOTIR)
RETURNING    PhaseID
INTO STRICT _PhaseID;

RETURN _PhaseID;
END;
$$;
