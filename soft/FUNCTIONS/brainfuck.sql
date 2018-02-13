CREATE OR REPLACE FUNCTION Brainfuck(_STDIN text)
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
_LLVMIR text;
_Memory int[];
_DataPtr int;
_ProgPtr int;
_STDINPOS integer;
_STDOUT text;
_STDOUTBuffer int[];
_STDOUTBufferMax CONSTANT integer := 1024;
_STDOUTBufferSize integer;
_Str text;
BEGIN
SELECT LLVMIR INTO STRICT _LLVMIR FROM LLVMIR;
_Memory  := array_fill(0,array[30000]);
_DataPtr := 0;
_ProgPtr := 0;
_STDINPOS := 0;
_STDOUT := '';
LOOP
    SELECT
        Memory,
        DataPtr,
        ProgPtr,
        STDOUTBuffer,
        STDOUTBufferSize
    INTO
        _Memory,
        _DataPtr,
        _ProgPtr,
        _STDOUTBuffer,
        _STDOUTBufferSize
    FROM LLVMIR_Run(
        _LLVMIR           := CASE WHEN _ProgPtr <> 0 THEN replace(_LLVMIR, 'entry:', 'br label %post_'||_ProgPtr::text) ELSE _LLVMIR END,
        _Memory           := _Memory,
        _DataPtr          := _DataPtr,
        _STDOUTBufferSize := _STDOUTBufferMax
    );
--    RAISE NOTICE 'DataPtr % ProgPtr % NodeType % STDOUTBuffer % STDOUTBufferSize %', _DataPtr, _ProgPtr, Node_Type(_ProgPtr), _STDOUTBuffer, _STDOUTBufferSize;
    IF _STDOUTBufferSize < _STDOUTBufferMax THEN
        _Str := '';
        FOR _i IN REVERSE _STDOUTBufferMax..(_STDOUTBufferSize+1) LOOP
            _Str := _Str || chr(_STDOUTBuffer[_i]);
        END LOOP;
        RAISE NOTICE '%', _Str;
        _STDOUT := _STDOUT || _Str;
    END IF;
    IF _ProgPtr = 0 THEN
        EXIT;
    ELSIF Node_Type(_ProgPtr) = 'READ_STDIN' THEN
        _STDINPOS := _STDINPOS + 1;
        _Memory[_DataPtr + 1] := ascii(substr(_STDIN, _STDINPOS, 1));
    ELSIF Node_Type(_ProgPtr) = 'WRITE_STDOUT' THEN
        -- already handled
    ELSE
        RAISE EXCEPTION 'Invalid NodeType %', Node_Type(_ProgPtr);
    END IF;
END LOOP;
RETURN _STDOUT;
END;
$$;

SELECT * FROM Brainfuck('');

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