CREATE TABLE soft.Nodes (
NodeID          serial    NOT NULL,
NodeTypeID      integer   NOT NULL REFERENCES soft.NodeTypes(NodeTypeID),
Chars           integer[],
Visited         integer DEFAULT 0,
ValueType       regtype,
NameValue       name,
BooleanValue    boolean,
NumericValue    numeric,
IntegerValue    integer,
TextValue       text,
Deleted         boolean NOT NULL DEFAULT FALSE,
PRIMARY KEY (NodeID),
CHECK(Chars IS NULL OR (NULL <<>> ANY (Chars)) IS FALSE),
CHECK((ValueType IS NULL              AND NameValue IS     NULL AND BooleanValue IS     NULL AND NumericValue IS     NULL AND IntegerValue IS     NULL AND TextValue IS     NULL)
OR    (ValueType = 'name'::regtype    AND NameValue IS NOT NULL AND BooleanValue IS     NULL AND NumericValue IS     NULL AND IntegerValue IS     NULL AND TextValue IS     NULL)
OR    (ValueType = 'boolean'::regtype AND NameValue IS     NULL AND BooleanValue IS NOT NULL AND NumericValue IS     NULL AND IntegerValue IS     NULL AND TextValue IS     NULL)
OR    (ValueType = 'numeric'::regtype AND NameValue IS     NULL AND BooleanValue IS     NULL AND NumericValue IS NOT NULL AND IntegerValue IS     NULL AND TextValue IS     NULL)
OR    (ValueType = 'integer'::regtype AND NameValue IS     NULL AND BooleanValue IS     NULL AND NumericValue IS     NULL AND IntegerValue IS NOT NULL AND TextValue IS     NULL)
OR    (ValueType = 'text'::regtype    AND NameValue IS     NULL AND BooleanValue IS     NULL AND NumericValue IS     NULL AND IntegerValue IS     NULL AND TextValue IS NOT NULL))
);
