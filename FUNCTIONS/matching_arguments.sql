CREATE OR REPLACE FUNCTION soft.Matching_Arguments(oidvector,oidvector)
RETURNS boolean
LANGUAGE sql
SET search_path TO soft, public, pg_temp
AS $$
SELECT array_length($1,1) = array_length($2,1)
AND NOT EXISTS (
    SELECT 1
    FROM (
        SELECT ArgumentType, ORDINALITY AS ArgumentPosition FROM unnest($1) WITH ORDINALITY AS ArgumentType
    ) AS FunctionInputArguments
    INNER JOIN (
        SELECT ArgumentType, ORDINALITY AS ArgumentPosition FROM unnest($2) WITH ORDINALITY AS ArgumentType
    ) AS ParentNodes ON FunctionInputArguments.ArgumentPosition = ParentNodes.ArgumentPosition
    WHERE ParentNodes.ArgumentType <> FunctionInputArguments.ArgumentType
    AND (FunctionInputArguments.ArgumentType::regtype <> 'anyelement'::regtype
    OR ParentNodes.ArgumentType = 'name'::regtype)
)
$$;
