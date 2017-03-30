CREATE OPERATOR <<>> (
    PROCEDURE = opr_isnotdistinctfrom,
    LEFTARG = anyelement,
    RIGHTARG = anyelement
);
