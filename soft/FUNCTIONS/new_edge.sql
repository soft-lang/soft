CREATE OR REPLACE FUNCTION New_Edge(
_ProgramID    integer,
_ParentNodeID integer,
_ChildNodeID  integer
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_BirthPhaseID integer;
_EdgeID       integer;
BEGIN

SELECT PhaseID INTO STRICT _BirthPhaseID FROM Programs WHERE ProgramID = _ProgramID;

INSERT INTO Edges ( ProgramID,  ParentNodeID,  ChildNodeID,  BirthPhaseID)
VALUES            (_ProgramID, _ParentNodeID, _ChildNodeID, _BirthPhaseID)
RETURNING    EdgeID
INTO STRICT _EdgeID;

RETURN _EdgeID;

END;
$$;
