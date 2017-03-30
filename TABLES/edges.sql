CREATE TABLE soft.Edges (
EdgeID       serial  NOT NULL,
ParentNodeID integer NOT NULL REFERENCES soft.Nodes(NodeID),
ChildNodeID  integer NOT NULL REFERENCES soft.Nodes(NodeID),
Deleted      boolean NOT NULL DEFAULT FALSE,
PRIMARY KEY (EdgeID),
CHECK (ParentNodeID <> ChildNodeID)
);
