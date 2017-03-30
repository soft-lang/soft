CREATE OR REPLACE FUNCTION public.opr_isnotdistinctfrom(anyelement, anyelement)
RETURNS boolean LANGUAGE SQL IMMUTABLE AS $$
SELECT $1 IS NOT DISTINCT FROM $2; 
$$;
