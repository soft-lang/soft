CREATE OR REPLACE FUNCTION Get_Files(_Path text, _FileSuffix text DEFAULT NULL)
RETURNS TABLE (
FilePath    text,
FileContent text
)
LANGUAGE plpgsql
AS $$
DECLARE
_File text;
BEGIN

IF (pg_stat_file(_Path)).isdir THEN
    FOR _File IN
    SELECT * FROM pg_ls_dir(_Path)
    LOOP
        IF _File ~ '^\.' THEN
            CONTINUE;
        END IF;
        RETURN QUERY
        SELECT * FROM Get_Files(_Path||'/'||_File, _FileSuffix);
    END LOOP;
    RETURN;
END IF;

IF _Path !~ _FileSuffix THEN
    RETURN;
END IF;

FilePath    := _Path;
FileContent := pg_read_file(_Path);
RETURN NEXT;

RETURN;
END;
$$;
