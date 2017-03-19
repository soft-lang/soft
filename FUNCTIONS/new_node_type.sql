CREATE OR REPLACE FUNCTION soft.New_Node_Type(
_Language          text,
_NodeType          text,
_Literal           text    DEFAULT NULL,
_LiteralPattern    text    DEFAULT NULL,
_NodePattern       text    DEFAULT NULL,
_Constructor       text    DEFAULT NULL,
_Eval              text    DEFAULT NULL,
_ValueType         regtype DEFAULT NULL,
_Input             text    DEFAULT NULL,
_Output            text    DEFAULT NULL,
_PreVisitFunction  text    DEFAULT NULL,
_PostVisitFunction text    DEFAULT NULL
)
RETURNS integer
LANGUAGE plpgsql
SET search_path TO soft, public, pg_temp
AS $$
DECLARE
_NodeTypeID       integer;
_LanguageID       integer;
BEGIN
SELECT LanguageID INTO STRICT _LanguageID FROM Languages WHERE Language = _Language;

INSERT INTO NodeTypes ( LanguageID,  NodeType,  Literal, LiteralLength,           LiteralPattern,       NodePattern,  ValueType,  Input,  Output,  PreVisitFunction,  PostVisitFunction)
VALUES                (_LanguageID, _NodeType, _Literal, length(_Literal), '^('||_LiteralPattern||')', _NodePattern, _ValueType, _Input, _Output, _PreVisitFunction, _PostVisitFunction)
RETURNING    NodeTypeID
INTO STRICT _NodeTypeID;

RETURN _NodeTypeID;
END;
$$;


