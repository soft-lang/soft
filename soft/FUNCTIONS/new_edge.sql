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
_ExistPhaseID integer;
_EdgeID       integer;
BEGIN

SELECT
    BirthPhase.PhaseID,
    ExistPhase.PhaseID
INTO STRICT
    _BirthPhaseID,
    _ExistPhaseID
FROM Programs
INNER JOIN Phases AS BirthPhase ON BirthPhase.PhaseID    = Programs.PhaseID
INNER JOIN Phases AS ExistPhase ON ExistPhase.LanguageID = BirthPhase.LanguageID
                               AND ExistPhase.PhaseID    > BirthPhase.PhaseID
WHERE Programs.ProgramID = _ProgramID
ORDER BY ExistPhase.PhaseID
LIMIT 1;

INSERT INTO Edges ( ProgramID,  ParentNodeID,  ChildNodeID,  BirthPhaseID,  ExistPhaseID)
VALUES            (_ProgramID, _ParentNodeID, _ChildNodeID, _BirthPhaseID, _ExistPhaseID)
RETURNING    EdgeID
INTO STRICT _EdgeID;

RETURN _EdgeID;

END;
$$;
