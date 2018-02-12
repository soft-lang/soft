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
        ProgPtr
    INTO
        _Memory,
        _DataPtr,
        _ProgPtr
    FROM LLVMIR_Run(
        _LLVMIR  := CASE WHEN _ProgPtr <> 0 THEN replace(_LLVMIR, ';ENTRY', 'br label %post_'||_ProgPtr::text) ELSE _LLVMIR END,
        _Memory  := _Memory,
        _DataPtr := _DataPtr
    );
    IF _ProgPtr = 0 THEN
        EXIT;
    ELSIF Node_Type(_ProgPtr) = 'WRITE_STDOUT' THEN
        _STDOUT := _STDOUT || chr(_Memory[_DataPtr + 1]);
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