CREATE OR REPLACE FUNCTION New_Edge(
_ProgramID        integer,
_ParentNodeID     integer,
_ChildNodeID      integer,
_ClonedRootNodeID integer   DEFAULT NULL
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_BirthPhaseID integer;
_EdgeID       integer;
_ClonedFromParentNodeID integer;
_ClonedFromChildNodeID  integer;
BEGIN

SELECT PhaseID INTO STRICT _BirthPhaseID FROM Programs WHERE ProgramID = _ProgramID;

INSERT INTO Edges ( ProgramID,  ParentNodeID,  ChildNodeID,  BirthPhaseID,  ClonedRootNodeID)
VALUES            (_ProgramID, _ParentNodeID, _ChildNodeID, _BirthPhaseID, _ClonedRootNodeID)
RETURNING    EdgeID
INTO STRICT _EdgeID;

SELECT ClonedFromNodeID INTO _ClonedFromParentNodeID FROM Nodes WHERE NodeID = _ParentNodeID;
SELECT ClonedFromNodeID INTO _ClonedFromChildNodeID  FROM Nodes WHERE NodeID = _ChildNodeID;

RAISE NOTICE 'New_Edge % -> % (% -> %)', _ClonedFromParentNodeID, _ClonedFromChildNodeID, _ParentNodeID, _ChildNodeID;

RETURN _EdgeID;

END;
$$;
