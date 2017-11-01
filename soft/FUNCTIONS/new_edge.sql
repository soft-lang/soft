CREATE OR REPLACE FUNCTION New_Edge(
_ParentNodeID     integer,
_ChildNodeID      integer,
_ClonedFromEdgeID integer DEFAULT NULL,
_ClonedRootNodeID integer DEFAULT NULL,
_EnvironmentID    integer DEFAULT 0
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID    integer;
_BirthPhaseID integer;
_EdgeID       integer;
BEGIN

SELECT DISTINCT ProgramID
INTO    STRICT _ProgramID
FROM Nodes
WHERE NodeID IN (_ParentNodeID,_ChildNodeID);

SELECT            PhaseID
INTO STRICT _BirthPhaseID
FROM Programs
WHERE ProgramID = _ProgramID;

INSERT INTO Edges ( ProgramID,  ParentNodeID,  ChildNodeID,  BirthPhaseID,  ClonedFromEdgeID,  ClonedRootNodeID,  EnvironmentID)
VALUES            (_ProgramID, _ParentNodeID, _ChildNodeID, _BirthPhaseID, _ClonedFromEdgeID, _ClonedRootNodeID, _EnvironmentID)
RETURNING    EdgeID
INTO STRICT _EdgeID;

RETURN _EdgeID;

END;
$$;
