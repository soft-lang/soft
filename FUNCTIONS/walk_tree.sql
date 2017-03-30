CREATE OR REPLACE FUNCTION soft.Walk_Tree(_ProgramID integer)
RETURNS boolean
LANGUAGE plpgsql
SET search_path TO soft, public, pg_temp
AS $$
DECLARE
_NodeID integer;
_ValueType regtype;
_ParentNodeID integer;
_ChildNodeID integer;
_OK boolean;
_Visited integer;
_NodeType text;
BEGIN

SELECT NodeID INTO STRICT _NodeID FROM Programs WHERE ProgramID = _ProgramID;

SELECT Nodes.ValueType, Nodes.Visited, NodeTypes.NodeType INTO STRICT _ValueType, _Visited, _NodeType FROM Nodes
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
WHERE NodeID = _NodeID;

IF _ValueType IS NULL OR EXISTS (
    SELECT 1 FROM pg_proc
    INNER JOIN pg_namespace ON pg_namespace.oid = pg_proc.pronamespace
    WHERE pg_namespace.nspname = 'soft'
    AND pg_proc.proname = _NodeType
)
THEN
    SELECT Edges.ParentNodeID
    INTO        _ParentNodeID
    FROM Edges
    INNER JOIN Nodes     ON Nodes.NodeID         = Edges.ParentNodeID
    INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
    WHERE Edges.ChildNodeID = _NodeID
    AND Nodes.Visited < _Visited
    AND (
        Nodes.ValueType IS NULL
        OR
        EXISTS (
            SELECT 1 FROM pg_proc
            INNER JOIN pg_namespace ON pg_namespace.oid = pg_proc.pronamespace
            WHERE pg_namespace.nspname = 'soft'
            AND pg_proc.proname = NodeTypes.NodeType
        )
    )
    ORDER BY Edges.EdgeID
    LIMIT 1;
    IF FOUND THEN
        RAISE NOTICE '% WALK NodeID % GOTO PARENT %', _Visited, _NodeID, _ParentNodeID;
        UPDATE Programs SET NodeID = _ParentNodeID WHERE ProgramID = _ProgramID RETURNING TRUE INTO STRICT _OK;
        PERFORM Set_Visited(_ParentNodeID, _Visited);
        RETURN TRUE;
    END IF;

    RAISE NOTICE '% WALK NodeID % EVAL', _Visited, _NodeID;

    PERFORM Eval_Node(_NodeID);

    IF (SELECT NodeID FROM Programs WHERE ProgramID = _ProgramID) = _NodeID THEN
        SELECT ChildNodeID
        INTO  _ChildNodeID
        FROM Edges
        WHERE ParentNodeID = _NodeID;
        IF FOUND THEN
            RAISE NOTICE '% WALK TO CHILD NODE %', _Visited, _ChildNodeID;
            UPDATE Programs SET NodeID = _ChildNodeID WHERE ProgramID = _ProgramID RETURNING TRUE INTO STRICT _OK;
        ELSE
            RETURN FALSE;
        END IF;
    ELSE
        RAISE NOTICE '% WALK NEXT NODE SET BY EVAL %', _Visited, (SELECT NodeID FROM Programs WHERE ProgramID = _ProgramID);
    END IF;

    RETURN TRUE;
ELSE
    RAISE NOTICE '% WALK NODE % IS A VALUE OF TYPE %, cannot eval', _Visited, _NodeID, _ValueType;
    RETURN FALSE;
END IF;

RETURN TRUE;
END;
$$;
