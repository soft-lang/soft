CREATE OR REPLACE FUNCTION "MAP_VARIABLES"."LEAVE_FUNCTION_DECLARATION"(_NodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_NumParameters integer;
_MaxParameters integer;
_OK            boolean;
BEGIN
PERFORM Set_Walkable(_NodeID, FALSE);

IF Find_Node(_NodeID := _NodeID, _Descend := FALSE, _Strict := FALSE, _Path := '-> DECLARATION -> STATEMENTS -> PROGRAM') IS NULL THEN
    -- Not a globally declared function, so might be a closure.
    UPDATE Nodes
    SET Closure = TRUE
    FROM Get_Closure_Nodes(_NodeID) AS CapturedVariableNodeID
    WHERE Nodes.NodeID = CapturedVariableNodeID;
    IF FOUND THEN
        UPDATE Nodes
        SET Closure = TRUE
        WHERE NodeID = _NodeID
        RETURNING TRUE INTO STRICT _OK;
    END IF;
END IF;

_NumParameters := Count_Parents(Parent(_NodeID,'ARGUMENTS'));
_MaxParameters := (Language(_NodeID)).MaxParameters;
IF _NumParameters > _MaxParameters THEN
    PERFORM Error(
        _NodeID := _NodeID,
        _ErrorType := 'TOO_MANY_PARAMETERS',
        _ErrorInfo := hstore(ARRAY[
            ['NumParameters', _NumParameters::text],
            ['MaxParameters', _MaxParameters::text]
        ])
    );
    RETURN FALSE;
END IF;

RETURN TRUE;
END;
$$;
