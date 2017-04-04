CREATE TABLE NodeTypes (
NodeTypeID         serial  NOT NULL,
NodeType           text    NOT NULL,
LanguageID         integer NOT NULL REFERENCES Languages(LanguageID),
TerminalType       regtype,
NodeGroup          text,
Literal            text,
LiteralLength      integer,
LiteralPattern     text,
NodePattern        text,
PrologueNodeTypeID integer,
EpilogueNodeTypeID integer,
GrowFromNodeTypeID integer,
GrowIntoNodeTypeID integer,
NodeSeverity       severity,
PRIMARY KEY (NodeTypeID),
CHECK (NodeType ~ '^[A-Z_]+$'),
UNIQUE (LanguageID, NodeTypeID),
UNIQUE (LanguageID, NodeType),
UNIQUE (LanguageID, Literal),
UNIQUE (LanguageID, LiteralPattern),
UNIQUE (LanguageID, NodePattern),
CHECK ((Literal IS     NULL AND LiteralPattern IS     NULL AND NodePattern IS     NULL)
OR     (Literal IS NOT NULL AND LiteralPattern IS     NULL AND NodePattern IS     NULL)
OR     (Literal IS     NULL AND LiteralPattern IS NOT NULL AND NodePattern IS     NULL)
OR     (Literal IS     NULL AND LiteralPattern IS     NULL AND NodePattern IS NOT NULL)),
CHECK ((Literal IS NULL) = (LiteralLength IS NULL)),
CHECK (length(Literal) = LiteralLength),
CHECK ((GrowFromNodeTypeID IS NULL) OR (GrowIntoNodeTypeID IS NULL))
);

ALTER TABLE NodeTypes ADD FOREIGN KEY (LanguageID, PrologueNodeTypeID) REFERENCES NodeTypes(LanguageID, NodeTypeID);
ALTER TABLE NodeTypes ADD FOREIGN KEY (LanguageID, EpilogueNodeTypeID) REFERENCES NodeTypes(LanguageID, NodeTypeID);
ALTER TABLE NodeTypes ADD FOREIGN KEY (LanguageID, GrowFromNodeTypeID) REFERENCES NodeTypes(LanguageID, NodeTypeID);
ALTER TABLE NodeTypes ADD FOREIGN KEY (LanguageID, GrowIntoNodeTypeID) REFERENCES NodeTypes(LanguageID, NodeTypeID);
