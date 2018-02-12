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
_STDOUTSize integer;
BEGIN
SELECT LLVMIR INTO STRICT _LLVMIR FROM LLVMIR;
_Memory  := array_fill(0,array[30000]);
_STDOUTBuffer := array_fill(0,array[30000]);
_DataPtr := 0;
_ProgPtr := 0;
_STDINPOS := 0;
_STDOUTSize := 0;
_STDOUT := '';
LOOP
    SELECT
        Memory,
        DataPtr,
        ProgPtr,
        STDOUTBuffer,
        STDOUTSize
    INTO
        _Memory,
        _DataPtr,
        _ProgPtr,
        _STDOUTBuffer,
        _STDOUTSize
    FROM LLVMIR_Run(
        _LLVMIR  := CASE WHEN _ProgPtr <> 0 THEN replace(_LLVMIR, 'entry:', 'br label %post_'||_ProgPtr::text) ELSE _LLVMIR END,
        _Memory  := _Memory,
        _DataPtr := _DataPtr
    );
--    RAISE NOTICE 'Memory % DataPtr % ProgPtr % STDOUTBuffer % STDOUTSize %', _Memory, _DataPtr, _ProgPtr, _STDOUTBuffer, _STDOUTSize;
    IF _STDOUTSize > 0 THEN
        FOR _i IN 1.._STDOUTSize LOOP
            _STDOUT := _STDOUT || chr(_STDOUTBuffer[_i]);
        END LOOP;
    END IF;
    IF _ProgPtr = 0 THEN
        EXIT;
    ELSIF Node_Type(_ProgPtr) = 'READ_STDIN' THEN
        _STDINPOS := _STDINPOS + 1;
        _Memory[_DataPtr + 1] := ascii(substr(_STDIN, _STDINPOS, 1));
    ELSE
        RAISE EXCEPTION 'Invalid NodeType %', Node_Type(_ProgPtr);
    END IF;
END LOOP;
RETURN _STDOUT;
END;
$$;

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