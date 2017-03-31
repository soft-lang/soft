CREATE OR REPLACE FUNCTION New_Edge(
_PhaseID    integer,
_FromNodeID integer,
_ToNodeID   integer
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_EdgeID integer;
BEGIN

INSERT INTO Edges ( FromNodeID,  ToNodeID, BirthPhaseID)
VALUES            (_FromNodeID, _ToNodeID,     _PhaseID)
RETURNING    EdgeID
INTO STRICT _EdgeID;

RETURN _EdgeID;

END;
$$;
