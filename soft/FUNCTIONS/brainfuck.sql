CREATE OR REPLACE FUNCTION Brainfuck(_STDIN text)
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
_LLVMIR text;
_Data int[];
_Size integer;
_Ptr int;
_Ret int;
_STDINPOS integer;
_STDOUT text;
_STDOUTBuffer int[];
_STDOUTBufferMax CONSTANT integer := 256;
_STDOUTRemaining integer;
_Str text;
_ArgumentNodeID integer;
_Argument integer;
_Grow integer;
BEGIN
SELECT LLVMIR INTO STRICT _LLVMIR FROM LLVMIR;
_Size := 1;
_Data := array_fill(0,array[_Size]);
_Ptr := 0;
_Ret := 0;
_STDINPOS := 0;
_STDOUT := '';
LOOP
    RAISE NOTICE '=> Data % Size % Ptr % STDOUTRemaining %', _Data, _Size, _Ptr, _STDOUTBufferMax;
    SELECT
        Data,
        Ptr,
        Ret,
        STDOUTBuffer,
        STDOUTRemaining
    INTO
        _Data,
        _Ptr,
        _Ret,
        _STDOUTBuffer,
        _STDOUTRemaining
    FROM LLVMIR_Run(
        _LLVMIR          := CASE WHEN _Ret <> 0 THEN replace(_LLVMIR, 'entry:', 'br label %Node'||_Ret::text) ELSE _LLVMIR END,
        _Data            := _Data,
        _Size            := _Size,
        _Ptr             := _Ptr,
        _STDOUTRemaining := _STDOUTBufferMax
    );
    RAISE NOTICE '<= Data % Ptr % Ret % STDOUTBuffer % STDOUTRemaining %', _Data, _Ptr, _Ret, _STDOUTBuffer, _STDOUTRemaining;
    IF _STDOUTRemaining < _STDOUTBufferMax THEN
        _Str := '';
        FOR _i IN REVERSE _STDOUTBufferMax..(_STDOUTRemaining+1) LOOP
            _Str := _Str || chr(_STDOUTBuffer[_i]);
        END LOOP;
        RAISE NOTICE '%', _Str;
        _STDOUT := _STDOUT || _Str;
    END IF;
    IF _Ret = 0 THEN
        EXIT;
    ELSIF Node_Type(_Ret) = 'DEC_PTR' THEN
        RAISE EXCEPTION 'Tried to move data pointer before first cell';
    ELSIF Node_Type(_Ret) IN ('INC_PTR', 'LOOP_MOVE_DATA', 'LOOP_MOVE_PTR') THEN
        _ArgumentNodeID := Parent(_Ret, 'ARGUMENT');
        _Argument := COALESCE(Primitive_Value(_ArgumentNodeID)::integer, 1);
        IF _Argument < 0 THEN
            RAISE EXCEPTION 'Tried to move data pointer before first cell';
        END IF;
        _Grow := GREATEST(_Size, _Argument);
        RAISE NOTICE 'Growing memory with % to allow moving data pointer % forward', _Grow, _Argument;
        _Size := _Size + _Grow;
        _Data  := _Data || array_fill(0,array[_Grow]);
    ELSIF Node_Type(_Ret) = 'READ_STDIN' THEN
        _STDINPOS := _STDINPOS + 1;
        _Data[_Ptr + 1] := ascii(substr(_STDIN, _STDINPOS, 1));
    ELSIF Node_Type(_Ret) = 'WRITE_STDOUT' THEN
        -- already handled
    ELSE
        RAISE EXCEPTION 'Invalid NodeType %', Node_Type(_Ret);
    END IF;
END LOOP;
RETURN _STDOUT;
END;
$$;

SELECT * FROM Brainfuck(E'12345678\n');

/*

-- Test of factor.bf:

joel=# SELECT * FROM Brainfuck(E'12345678\n');
        brainfuck         
--------------------------
 12345678: 2 3 3 47 14593+
 
(1 row)

Time: 1789.873 ms (00:01.790)
joel=#* 

*/