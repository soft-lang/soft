CREATE TABLE Edges (
EdgeID           serial      NOT NULL,
ProgramID        integer     NOT NULL REFERENCES Programs(ProgramID),
ParentNodeID     integer     NOT NULL REFERENCES Nodes(NodeID),
ChildNodeID      integer     NOT NULL REFERENCES Nodes(NodeID),
BirthPhaseID     integer     NOT NULL REFERENCES Phases(PhaseID),
BirthTime        timestamptz NOT NULL DEFAULT clock_timestamp(),
DeathPhaseID     integer              REFERENCES Phases(PhaseID),
DeathTime        timestamptz,
ClonedFromEdgeID integer              REFERENCES Edges(EdgeID),
ClonedRootNodeID integer              REFERENCES Nodes(NodeID),
PRIMARY KEY (EdgeID),
CHECK (ParentNodeID <> ChildNodeID),
CHECK (BirthPhaseID <= DeathPhaseID),
CHECK ((DeathPhaseID IS NULL) = (DeathTime IS NULL))
);

CREATE INDEX ON Edges(ChildNodeID, EdgeID)  WHERE DeathPhaseID IS NULL;
CREATE INDEX ON Edges(ParentNodeID, EdgeID) WHERE DeathPhaseID IS NULL;
CREATE INDEX ON Edges(ProgramID)    WHERE DeathPhaseID IS NULL;



CREATE INDEX ON Edges(ChildNodeID, ParentNodeID, EdgeID)  WHERE DeathPhaseID IS NULL;
CREATE INDEX ON Edges(ParentNodeID, ChildNodeID, EdgeID) WHERE DeathPhaseID IS NULL;
