CREATE OR REPLACE FUNCTION Pop_Walkable(boolean[])
RETURNS boolean[]
LANGUAGE sql
AS $$
SELECT $1[2:array_length($1,1)]
$$;
