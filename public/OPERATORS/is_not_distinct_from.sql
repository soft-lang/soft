CREATE OPERATOR <<>> (
    PROCEDURE = is_not_distinct_from,
    LEFTARG = anyelement,
    RIGHTARG = anyelement
);
