CREATE OR REPLACE FUNCTION "EVAL"."ENTER_LOOP_MOVE_PTR"(_NodeID integer)
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
_Argument       := Primitive_Value(_ArgumentNodeID)::integer;

IF _Array    IS NULL
OR _Ptr      IS NULL
OR _Argument IS NULL
THEN
    RAISE EXCEPTION 'Unexpected NULLs Array % Ptr % Argument % NodeID %', _Array, _Ptr, _Argument, _NodeID;
END IF;

LOOP
    IF _Array[_Ptr] = 0 THEN
        EXIT;
    END IF;

    IF _Ptr + _Argument > cardinality(_Array) THEN
        -- Expand array and set new cells to zero
        FOR _i IN (cardinality(_Array)+1)..(_Ptr + _Argument) LOOP
            _Array[_i] = 0;
        END LOOP;
        PERFORM Set_Node_Value(_ArrayNodeID, _Array);
    END IF;
    IF _Ptr + _Argument < 1 THEN
        RAISE EXCEPTION 'Out of bounds error! Tried to decrement pointer before first cell. NodeID %', _NodeID;
    END IF;
    _Ptr := _Ptr + _Argument;
    _Value := _Array[_Ptr];
END LOOP;

PERFORM Set_Node_Value(_PtrNodeID,  _Ptr);
PERFORM Set_Node_Value(_DataNodeID, _Value);

RETURN;
END;
$$;
