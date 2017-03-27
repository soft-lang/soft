CREATE OR REPLACE FUNCTION soft.New_Bonsai_Schema(
_Language     text,
_BonsaiSchema text
)
RETURNS integer
LANGUAGE plpgsql
SET search_path TO soft, public, pg_temp
AS $$
DECLARE
_LanguageID     integer;
_BonsaiSchemaID integer;
BEGIN
SELECT LanguageID INTO STRICT _LanguageID FROM Languages WHERE Language = _Language;
IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_namespace WHERE nspname = _BonsaiSchema) THEN
    RAISE EXCEPTION 'Schema % does not exist', _BonsaiSchema;
END IF;

INSERT INTO BonsaiSchemas (LanguageID, BonsaiSchema) VALUES (_LanguageID, _BonsaiSchema) RETURNING BonsaiSchemaID INTO STRICT _BonsaiSchemaID;

RETURN _BonsaiSchemaID;
END;
$$;


