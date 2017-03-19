CREATE OR REPLACE FUNCTION soft.Tokenize(_LanguageID integer, _SourceCodeNodeID integer)
RETURNS boolean
LANGUAGE plpgsql
SET search_path TO soft, public, pg_temp
AS $$
DECLARE
_SourceCode     text;
_AtChar         integer;
_NodeTypeID     integer;
_Literal        text;
_LiteralLength  integer;
_Remainder      text;
_NumChars       integer;
_TokenNodeID    integer;
_ValueType      regtype;
_LiteralPattern text;
_Matches        text[];
_OK             boolean;
BEGIN

SELECT TextValue INTO STRICT _SourceCode FROM Nodes WHERE NodeID = _SourceCodeNodeID;

_NumChars := length(_SourceCode);

_AtChar := 1;
LOOP
    IF _AtChar > _NumChars THEN
        EXIT;
    END IF;

    _Remainder := substr(_SourceCode, _AtChar);

    IF _Remainder ~ '^\s+' THEN
        _Literal := substring(_Remainder from '^\s+');
        _AtChar := _AtChar + length(_Literal);
        CONTINUE;
    END IF;

    SELECT NodeTypeID,  ValueType,  Literal,  LiteralLength
    INTO  _NodeTypeID, _ValueType, _Literal, _LiteralLength
    FROM NodeTypes
    WHERE LanguageID = _LanguageID
    AND   Literal    = substr(_SourceCode, _AtChar, LiteralLength)
    ORDER BY LiteralLength DESC
    LIMIT 1;
    IF NOT FOUND THEN
        SELECT  NodeTypeID,  ValueType,  LiteralPattern
        INTO   _NodeTypeID, _ValueType, _LiteralPattern
        FROM NodeTypes
        WHERE LanguageID = _LanguageID
        AND   _Remainder ~ LiteralPattern
        ORDER BY NodeTypeID
        LIMIT 1;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Unable to tokenize, illegal character at % [%]: %', _AtChar, substr(_SourceCode, _AtChar, 1), _Remainder;
        END IF;
        _Matches       := regexp_matches(_Remainder, _LiteralPattern);
        _Literal       := _Matches[2];
        _LiteralLength := length(_Matches[1]);
    END IF;

    _TokenNodeID := New_Node(_NodeTypeID, _Literal, _ValueType);

    INSERT INTO Edges (     ParentNodeID,  ChildNodeID)
    VALUES            (_SourceCodeNodeID, _TokenNodeID)
    RETURNING TRUE INTO STRICT _OK;

    _AtChar := _AtChar + _LiteralLength;
END LOOP;

RETURN TRUE;
END;
$$;
