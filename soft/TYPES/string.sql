CREATE OR REPLACE FUNCTION stringin(cstring) RETURNS string
LANGUAGE internal STRICT IMMUTABLE
AS $$textin$$;

CREATE OR REPLACE FUNCTION stringout(string) RETURNS cstring
LANGUAGE internal STRICT IMMUTABLE
AS $$textout$$;

CREATE TYPE string (
    LIKE = text,
    INPUT = stringin,
    OUTPUT = stringout
);
