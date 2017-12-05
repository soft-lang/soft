CREATE OR REPLACE FUNCTION nodein(cstring) RETURNS node
LANGUAGE internal STRICT IMMUTABLE
AS $$textin$$;

CREATE OR REPLACE FUNCTION nodeout(node) RETURNS cstring
LANGUAGE internal STRICT IMMUTABLE
AS $$textout$$;

CREATE TYPE node (
    INTERNALLENGTH = variable,
    INPUT = nodein,
    OUTPUT = nodeout,
    CATEGORY = 't'
);
