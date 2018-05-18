CREATE OR REPLACE FUNCTION New_Node_Type(
_Language       text,
_NodeType       text,
_PrimitiveType  regtype  DEFAULT NULL,
_NodeGroup      text     DEFAULT NULL,
_Precedence     text     DEFAULT NULL,
_Literal        text     DEFAULT NULL,
_LiteralPattern text     DEFAULT NULL,
_NodePattern    text     DEFAULT NULL,
_Prologue       text     DEFAULT NULL,
_Epilogue       text     DEFAULT NULL,
_GrowFrom       text     DEFAULT NULL,
_GrowInto       text     DEFAULT NULL,
_NodeSeverity   severity DEFAULT NULL
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_NodeTypeID         integer;
_LanguageID         integer;
_PrologueNodeTypeID integer;
_EpilogueNodeTypeID integer;
_GrowFromNodeTypeID integer;
_GrowIntoNodeTypeID integer;
BEGIN
SELECT LanguageID INTO _LanguageID FROM Languages WHERE Language = _Language;
IF NOT FOUND THEN
    RAISE EXCEPTION 'Language "%" not found', _Language;
END IF;

IF _Prologue IS NOT NULL THEN
    SELECT NodeTypeID INTO _PrologueNodeTypeID FROM NodeTypes WHERE LanguageID = _LanguageID AND NodeType = _Prologue;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Prologue NodeType "%" for Language "%" not found', _Prologue, _Language;
    END IF;
END IF;

IF _Epilogue IS NOT NULL THEN
    SELECT NodeTypeID INTO _EpilogueNodeTypeID FROM NodeTypes WHERE LanguageID = _LanguageID AND NodeType = _Epilogue;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Epilogue NodeType "%" for Language "%" not found', _Epilogue, _Language;
    END IF;
END IF;

IF _GrowFrom IS NOT NULL THEN
    SELECT NodeTypeID INTO _GrowFromNodeTypeID FROM NodeTypes WHERE LanguageID = _LanguageID AND NodeType = _GrowFrom;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'GrowFrom NodeType "%" for Language "%" not found', _GrowFrom, _Language;
    END IF;
END IF;

IF _GrowInto IS NOT NULL THEN
    SELECT NodeTypeID INTO _GrowIntoNodeTypeID FROM NodeTypes WHERE LanguageID = _LanguageID AND NodeType = _GrowInto;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'GrowInto NodeType "%" for Language "%" not found', _GrowInto, _Language;
    END IF;
END IF;

IF EXISTS (
    SELECT 1 FROM NodeTypes
    WHERE LanguageID = _LanguageID
    AND   NodeGroup  = _NodeType
) THEN
    RAISE EXCEPTION 'Cannot use "%" as NodeType for Language "%" as it is already a NodeGroup', _NodeType, _Language;
END IF;

IF _NodeGroup IS NOT NULL
AND EXISTS (
    SELECT 1 FROM NodeTypes
    WHERE LanguageID = _LanguageID
    AND   NodeType   = _NodeGroup
) THEN
    RAISE EXCEPTION 'Cannot use "%" as NodeGroup for Language "%" as it is already a NodeType', _NodeGroup, _Language;
END IF;

INSERT INTO NodeTypes ( LanguageID,  NodeType,  PrimitiveType,  NodeGroup,  Precedence,  Literal, LiteralLength,     LiteralPattern,  NodePattern,  PrologueNodeTypeID,  EpilogueNodeTypeID,  GrowFromNodeTypeID,  GrowIntoNodeTypeID,  NodeSeverity)
VALUES                (_LanguageID, _NodeType, _PrimitiveType, _NodeGroup, _Precedence, _Literal, length(_Literal), _LiteralPattern, _NodePattern, _PrologueNodeTypeID, _EpilogueNodeTypeID, _GrowFromNodeTypeID, _GrowIntoNodeTypeID, _NodeSeverity)
RETURNING    NodeTypeID
INTO STRICT _NodeTypeID;

RETURN _NodeTypeID;
END;
$$;
