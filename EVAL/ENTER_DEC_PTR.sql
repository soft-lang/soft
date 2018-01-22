CREATE OR REPLACE FUNCTION "EVAL"."ENTER_DEC_PTR"(_NodeID integer)
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
_Ptr            := _Ptr - _Argument;
IF _Ptr < 1 THEN
    RAISE EXCEPTION 'Out of bounds error! Tried to decrement pointer before first cell. NodeID %', _NodeID;
END IF;
_Value := _Array[_Ptr];

PERFORM Set_Node_Value(_PtrNodeID,  _Ptr);
PERFORM Set_Node_Value(_DataNodeID, _Value);

RETURN;
END;
$$;
