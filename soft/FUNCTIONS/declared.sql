CREATE OR REPLACE FUNCTION Declared(_NodeID integer)
RETURNS integer
LANGUAGE plpgsql
AS $$
-- Returns the NodeID for the block where
-- the variable is declared, or NULL if it's
-- not a variable.
-- Useful to compare two nodes and see if they
-- are declared at the same block level.
DECLARE
_BlockLevelNodeID integer;
_Count            bigint;
BEGIN

SELECT
    E2.ChildNodeID,
    COUNT(*) OVER ()
INTO
    _BlockLevelNodeID,
    _Count
FROM Nodes           AS Variable
INNER JOIN NodeTypes AS VariableType    ON VariableType.NodeTypeID    = Variable.NodeTypeID
INNER JOIN Edges     AS E1              ON E1.ParentNodeID            = Variable.NodeID
INNER JOIN Nodes     AS Declaration     ON Declaration.NodeID         = E1.ChildNodeID
INNER JOIN NodeTypes AS DeclarationType ON DeclarationType.NodeTypeID = Declaration.NodeTypeID
INNER JOIN Edges     AS E2              ON E2.ParentNodeID            = Declaration.NodeID
WHERE Variable.NodeID          = _NodeID
AND   VariableType.NodeType    = 'VARIABLE'
AND   DeclarationType.NodeType = 'DECLARATION'
AND   Variable.DeathPhaseID    IS NULL
AND   E1.DeathPhaseID          IS NULL
AND   Declaration.DeathPhaseID IS NULL
AND   E2.DeathPhaseID          IS NULL
AND   Variable.NodeID = (
    -- Check that VARIABLE is on the left side of the DECLARATION
    -- since a VARIABLE declared somewhere else can also
    -- be a parent to a DECLARATION node, then on the right side.
    SELECT E3.ParentNodeID
    FROM Edges AS E3
    WHERE E3.ChildNodeID = Declaration.NodeID
    AND   E3.DeathPhaseID IS NULL
    ORDER BY E3.EdgeID
    LIMIT 1
);
IF NOT FOUND THEN
    RETURN NULL;
END IF;

IF _Count > 1 THEN
    RAISE EXCEPTION 'Cannot determine the block level where NodeID % is declared. Count %', _NodeID, _Count;
END IF;

RETURN _BlockLevelNodeID;
END;
$$;
