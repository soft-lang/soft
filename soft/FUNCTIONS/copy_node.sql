CREATE OR REPLACE FUNCTION Copy_Node(_FromNodeID integer, _ToNodeID integer)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_OK boolean;
BEGIN

UPDATE Nodes AS CopyTo SET
    ValueType    = CopyFrom.ValueType,
    NameValue    = CopyFrom.NameValue,
    BooleanValue = CopyFrom.BooleanValue,
    NumericValue = CopyFrom.NumericValue,
    IntegerValue = CopyFrom.IntegerValue,
    TextValue    = CopyFrom.TextValue
FROM Nodes AS CopyFrom
WHERE CopyFrom.NodeID = _FromNodeID
AND     CopyTo.NodeID = _ToNodeID
RETURNING TRUE INTO STRICT _OK;

RETURN TRUE;
END;
$$;
