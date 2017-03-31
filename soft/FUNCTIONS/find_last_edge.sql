CREATE OR REPLACE FUNCTION Find_Last_Edge(_NodeID integer)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_EdgeID integer;
_ChildNodeID integer;
_Commons integer[][];
_Path integer[][];
_Candidates integer[][];
BEGIN

FOR _ChildNodeID IN
SELECT ChildNodeID FROM Edges WHERE ParentNodeID = _NodeID ORDER BY ChildNodeID
LOOP
    WITH RECURSIVE
    Children AS (
    SELECT Edges.ChildNodeID, Edges.EdgeID FROM Edges WHERE Edges.ParentNodeID = _ChildNodeID
    UNION ALL
    SELECT ChildEdges.ChildNodeID, ChildEdges.EdgeID FROM Edges AS ChildEdges
    INNER JOIN Children ON Children.ChildNodeID = ChildEdges.ParentNodeID
    )
    SELECT array_agg(ARRAY[ChildNodeID,EdgeID]) INTO STRICT _Path FROM Children;

    IF _Commons IS NULL THEN
        _Commons := _Path;
        CONTINUE;
    END IF;

    _Candidates := _Commons;
    _Commons := NULL;
    FOR _i IN 1..array_length(_Candidates,1) LOOP
        FOR _j IN 1..array_length(_Path,1) LOOP
            IF _Candidates[_i][1] = _Path[_j][1] THEN
                _Commons := _Commons || ARRAY[[_Candidates[_i][1], GREATEST(_Candidates[_i][2], _Path[_j][2])]];
            END IF;
        END LOOP;
    END LOOP;

    IF _Commons IS NULL THEN
        RETURN NULL;
    END IF;
END LOOP;

RETURN _Commons[1][2];
END;
$$;
