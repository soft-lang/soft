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
BEGIN

RAISE NOTICE 'New_Edge % -> %', Get_Node_Label(_ParentNodeID), Get_Node_Label(_ChildNodeID);

SELECT PhaseID INTO STRICT _BirthPhaseID FROM Programs WHERE ProgramID = _ProgramID;

INSERT INTO Edges ( ProgramID,  ParentNodeID,  ChildNodeID,  BirthPhaseID,  ClonedRootNodeID)
VALUES            (_ProgramID, _ParentNodeID, _ChildNodeID, _BirthPhaseID, _ClonedRootNodeID)
RETURNING    EdgeID
INTO STRICT _EdgeID;

RETURN _EdgeID;

END;
$$;
