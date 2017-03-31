CREATE OR REPLACE FUNCTION New_Node_Type(
_Language         text,
_NodeType         text,
_TerminalType     regtype DEFAULT NULL,
_NodeGroup        text    DEFAULT NULL,
_Literal          text    DEFAULT NULL,
_LiteralPattern   text    DEFAULT NULL,
_NodePattern      text    DEFAULT NULL,
_PrologueNodeType text    DEFAULT NULL,
_EpilogueNodeType text    DEFAULT NULL,
_GrowFromNodeType text    DEFAULT NULL,
_GrowIntoNodeType text    DEFAULT NULL
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

IF _PrologueNodeType IS NOT NULL THEN SELECT NodeTypeID INTO STRICT _PrologueNodeTypeID FROM NodeTypes WHERE LanguageID = _LanguageID AND NodeType = _PrologueNodeType; END IF;
IF _EpilogueNodeType IS NOT NULL THEN SELECT NodeTypeID INTO STRICT _EpilogueNodeTypeID FROM NodeTypes WHERE LanguageID = _LanguageID AND NodeType = _EpilogueNodeType; END IF;
IF _GrowFromNodeType IS NOT NULL THEN SELECT NodeTypeID INTO STRICT _GrowFromNodeTypeID FROM NodeTypes WHERE LanguageID = _LanguageID AND NodeType = _GrowFromNodeType; END IF;
IF _GrowIntoNodeType IS NOT NULL THEN SELECT NodeTypeID INTO STRICT _GrowIntoNodeTypeID FROM NodeTypes WHERE LanguageID = _LanguageID AND NodeType = _GrowIntoNodeType; END IF;

INSERT INTO NodeTypes ( LanguageID,  NodeType,  TerminalType,  NodeGroup,  Literal, LiteralLength,           LiteralPattern,       NodePattern,  PrologueNodeTypeID,  EpilogueNodeTypeID,  GrowFromNodeTypeID,  GrowIntoNodeTypeID)
VALUES                (_LanguageID, _NodeType, _TerminalType, _NodeGroup, _Literal, length(_Literal), '^('||_LiteralPattern||')', _NodePattern, _PrologueNodeTypeID, _EpilogueNodeTypeID, _GrowFromNodeTypeID, _GrowIntoNodeTypeID)
RETURNING    NodeTypeID
INTO STRICT _NodeTypeID;

RETURN _NodeTypeID;
END;
$$;
