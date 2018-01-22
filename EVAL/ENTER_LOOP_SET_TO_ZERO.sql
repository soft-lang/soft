CREATE OR REPLACE FUNCTION "EVAL"."ENTER_LOOP_SET_TO_ZERO"(_NodeID integer)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_DataNodeID     integer;
_ArrayNodeID    integer;
_Array          integer[];
_PtrNodeID      integer;
_Ptr            integer;
_Value          integer;
BEGIN

_DataNodeID     := Parent(_NodeID, 'DATA');
_ArrayNodeID    := Parent(_DataNodeID, 'ARRAY');
_PtrNodeID      := Parent(_DataNodeID, 'PTR');
_Array          := Primitive_Value(_ArrayNodeID)::integer[];
_Ptr            := Primitive_Value(_PtrNodeID)::integer;

IF _Array    IS NULL
OR _Ptr      IS NULL
THEN
    RAISE EXCEPTION 'Unexpected NULLs Array % Ptr % NodeID %', _Array, _Ptr, _NodeID;
END IF;

_Value       := 0;
_Array[_Ptr] := _Value;

PERFORM Set_Node_Value(_DataNodeID,  _Value);
PERFORM Set_Node_Value(_ArrayNodeID, _Array);

RETURN;
END;
$$;
