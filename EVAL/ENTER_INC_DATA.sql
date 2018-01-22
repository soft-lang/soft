CREATE OR REPLACE FUNCTION "EVAL"."ENTER_INC_DATA"(_NodeID integer)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_DataNodeID     integer;
_ArgumentNodeID integer;
_Argument       integer;
_ArrayNodeID    integer;
_Array          integer[];
_PtrNodeID      integer;
_Ptr            integer;
_Value          integer;
BEGIN

_DataNodeID     := Parent(_NodeID, 'DATA');
_ArgumentNodeID := Parent(_NodeID, 'ARGUMENT');
_ArrayNodeID    := Parent(_DataNodeID, 'ARRAY');
_PtrNodeID      := Parent(_DataNodeID, 'PTR');
_Array          := Primitive_Value(_ArrayNodeID)::integer[];
_Ptr            := Primitive_Value(_PtrNodeID)::integer;
_Argument       := COALESCE(Primitive_Value(_ArgumentNodeID)::integer, 1);
_Value          := _Array[_Ptr] + _Argument;
_Array[_Ptr]    := _Value;

PERFORM Set_Node_Value(_DataNodeID,  _Value);
PERFORM Set_Node_Value(_ArrayNodeID, _Array);

RETURN;
END;
$$;
