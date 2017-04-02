CREATE OR REPLACE FUNCTION Exists_Node_Type_Function(_NodeType text, _LanguageID integer)
RETURNS boolean
LANGUAGE sql
STABLE
AS $$
SELECT EXISTS (
    SELECT 1 FROM pg_proc
    INNER JOIN pg_namespace ON pg_namespace.oid = pg_proc.pronamespace
    INNER JOIN Phases       ON Phases.Phase     = pg_namespace.nspname
    WHERE pg_proc.proname   = $1
    AND   Phases.LanguageID = $2
)
$$;
