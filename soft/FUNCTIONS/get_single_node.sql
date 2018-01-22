CREATE OR REPLACE FUNCTION Get_Single_Node(_NodeID integer, _NodeType text)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_FoundNodeID integer;
_Count       bigint;
BEGIN

SELECT N2.NodeID, COUNT(*) OVER ()
INTO _FoundNodeID, _Count
FROM Nodes AS N1
INNER JOIN Nodes AS N2 ON N2.ProgramID = N1.ProgramID
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = N2.NodeTypeID
WHERE N1.NodeID = _NodeID
AND   NodeTypes.NodeType = _NodeType
LIMIT 1;
IF _Count = 1 THEN
    RETURN _FoundNodeID;
END IF;

IF _Count > 1 THEN
    RAISE EXCEPTION 'Found % nodes, excepted one or none. NodeID % NodeType %', _Count, _NodeID, _NodeType;
END IF;

RETURN NULL;
END;
$$;
