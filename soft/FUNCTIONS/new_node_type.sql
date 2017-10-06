CREATE OR REPLACE FUNCTION New_Node_Type(
_Language       text,
_NodeType       text,
_PrimitiveType   regtype  DEFAULT NULL,
_NodeGroup      text     DEFAULT NULL,
_Literal        text     DEFAULT NULL,
_LiteralPattern text     DEFAULT NULL,
_NodePattern    text     DEFAULT NULL,
_Prologue       text     DEFAULT NULL,
_Epilogue       text     DEFAULT NULL,
_GrowFrom       text     DEFAULT NULL,
_GrowInto       text     DEFAULT NULL,
_NodeSeverity   severity DEFAULT NULL,
_Precedence     text     DEFAULT NULL
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
SELECT LanguageID INTO STRICT _LanguageID FROM Languages WHERE Language = _Language;

IF _Prologue IS NOT NULL THEN SELECT NodeTypeID INTO STRICT _PrologueNodeTypeID FROM NodeTypes WHERE LanguageID = _LanguageID AND NodeType = _Prologue; END IF;
IF _Epilogue IS NOT NULL THEN SELECT NodeTypeID INTO STRICT _EpilogueNodeTypeID FROM NodeTypes WHERE LanguageID = _LanguageID AND NodeType = _Epilogue; END IF;
IF _GrowFrom IS NOT NULL THEN SELECT NodeTypeID INTO STRICT _GrowFromNodeTypeID FROM NodeTypes WHERE LanguageID = _LanguageID AND NodeType = _GrowFrom; END IF;
IF _GrowInto IS NOT NULL THEN SELECT NodeTypeID INTO STRICT _GrowIntoNodeTypeID FROM NodeTypes WHERE LanguageID = _LanguageID AND NodeType = _GrowInto; END IF;

INSERT INTO NodeTypes ( LanguageID,  NodeType,  PrimitiveType,  NodeGroup,  Literal, LiteralLength,           LiteralPattern,       NodePattern,  PrologueNodeTypeID,  EpilogueNodeTypeID,  GrowFromNodeTypeID,  GrowIntoNodeTypeID,  NodeSeverity,  Precedence)
VALUES                (_LanguageID, _NodeType, _PrimitiveType, _NodeGroup, _Literal, length(_Literal), '^('||_LiteralPattern||')', _NodePattern, _PrologueNodeTypeID, _EpilogueNodeTypeID, _GrowFromNodeTypeID, _GrowIntoNodeTypeID, _NodeSeverity, _Precedence)
RETURNING    NodeTypeID
INTO STRICT _NodeTypeID;

RETURN _NodeTypeID;
END;
$$;
