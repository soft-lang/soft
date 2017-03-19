CREATE TABLE soft.NodeTypes (
NodeTypeID        serial  NOT NULL,
LanguageID        integer NOT NULL REFERENCES soft.Languages(LanguageID),
NodeType          text    NOT NULL,
Literal           text,
LiteralLength     integer,
LiteralPattern    text,
NodePattern       text,
ValueType         regtype,
Input             text,
Output            text,
PreVisitFunction  text,
PostVisitFunction text,
PRIMARY KEY (NodeTypeID),
CHECK (NodeType ~ '^[A-Z_]+$'),
UNIQUE (LanguageID, NodeType),
UNIQUE (LanguageID, Literal),
UNIQUE (LanguageID, LiteralPattern),
UNIQUE (LanguageID, NodePattern),
CHECK((Literal IS     NULL AND LiteralPattern IS     NULL AND NodePattern IS     NULL)
OR    (Literal IS NOT NULL AND LiteralPattern IS     NULL AND NodePattern IS     NULL)
OR    (Literal IS     NULL AND LiteralPattern IS NOT NULL AND NodePattern IS     NULL)
OR    (Literal IS     NULL AND LiteralPattern IS     NULL AND NodePattern IS NOT NULL)),
CHECK((Literal IS NULL) = (LiteralLength IS NULL)),
CHECK(length(Literal) = LiteralLength)
);
