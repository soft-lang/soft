CREATE OR REPLACE FUNCTION LLVMIR(_NodeID integer, _LLVMIR text)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID integer;
_OK boolean;
BEGIN
SELECT       ProgramID
INTO STRICT _ProgramID
FROM Nodes
WHERE NodeID = _NodeID;

_LLVMIR := regexp_replace(_LLVMIR, '^\s*', E'\n'||'; >'||Node_Type(_NodeID)||_NodeID||E'\n');
_LLVMIR := regexp_replace(_LLVMIR, '(%\.\d+)', '\1.'||_NodeID, 'g');
_LLVMIR := regexp_replace(_LLVMIR, '(\.\d+):', '\1.'||_NodeID||':', 'g');
_LLVMIR := regexp_replace(_LLVMIR, '%NodeID', _NodeID::text, 'g');
_LLVMIR := regexp_replace(_LLVMIR, '\s*$', E'\n'||'; <'||Node_Type(_NodeID)||_NodeID||E'\n');

UPDATE LLVMIR
SET LLVMIR = LLVMIR || _LLVMIR
WHERE ProgramID = _ProgramID;
IF NOT FOUND THEN
    INSERT INTO LLVMIR ( ProgramID,  LLVMIR)
    VALUES             (_ProgramID, _LLVMIR)
    RETURNING TRUE INTO STRICT _OK;
END IF;

RETURN TRUE;
END;
$$;
