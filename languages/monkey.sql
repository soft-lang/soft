SELECT soft.New_Language(_Language := 'monkey');

SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'VARIABLE');
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'EQ',           _Literal         := '=');
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'PLUS',         _Literal         := '+',  _NodeGroup := 'OPS');
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'MINUS',        _Literal         := '-',  _NodeGroup := 'OPS');
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'BANG',         _Literal         := '!',  _NodeGroup := 'OPS');
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'ASTERISK',     _Literal         := '*',  _NodeGroup := 'OPS');
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'SLASH',        _Literal         := '/',  _NodeGroup := 'OPS');
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'LT',           _Literal         := '<',  _NodeGroup := 'OPS');
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'GT',           _Literal         := '>',  _NodeGroup := 'OPS');
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'EQ_EQ',        _Literal         := '==', _NodeGroup := 'OPS');
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'BANG_EQ',      _Literal         := '!=', _NodeGroup := 'OPS');
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'COMMA',        _Literal         := ',');
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'SEMICOLON',    _Literal         := ';');
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'COLON',        _Literal         := ':');
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'LPAREN',       _Literal         := '(');
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'RPAREN',       _Literal         := ')');
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'LBRACE',       _Literal         := '{');
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'RBRACE',       _Literal         := '}');
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'LBRACKET',     _Literal         := '[');
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'RBRACKET',     _Literal         := ']');
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'FUNCTION',     _Literal         := 'fn');
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'LET',          _Literal         := 'let');
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'IF',           _Literal         := 'if');
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'ELSE',         _Literal         := 'else');
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'RETURN',       _Literal         := 'return');
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'BOOLEAN',      _LiteralPattern  := '(true|false)',          _NodeGroup := 'VALUE', _ValueType := 'boolean'::regtype);
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'NUMERIC',      _LiteralPattern  := '([0-9]+\.[0-9]+)',      _NodeGroup := 'VALUE', _ValueType := 'numeric'::regtype);
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'INTEGER',      _LiteralPattern  := '([0-9]+)',              _NodeGroup := 'VALUE', _ValueType := 'integer'::regtype);
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'TEXT',         _LiteralPattern  := '"((?:[^"\\]|\\.)*)"',   _NodeGroup := 'VALUE', _ValueType := 'text'::regtype);
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'IDENTIFIER',   _LiteralPattern  := '([a-zA-Z_]+)',              _ValueType := 'name'::regtype);
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'STORE_ARGS',                                                               _NodePattern     := '(?:^| )(?:FUNCTION\d+ )(LPAREN\d+(?: IDENTIFIER\d+(?: COMMA\d+ IDENTIFIER\d+)*)? RPAREN\d+)');
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'GET_VARIABLE',  _ValueType := 'name'::regtype, _NodeGroup := 'VALUE',      _NodePattern     := '(?:^| )(IDENTIFIER\d+)(?:(?! (?:EQ|LPAREN|FUNCTION_ARGS)\d+) [A-Z_]+\d+|$)', _PreVisitFunction := 'GET_VARIABLE_NODE');
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'SET_VARIABLE',  _ValueType := 'name'::regtype,                             _NodePattern     := '(?:^| )(IDENTIFIER\d+) EQ\d+');
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'FUNCTION_NAME', _ValueType := 'name'::regtype, _NodeGroup := 'VALUE',      _NodePattern     := '(?:^| )(IDENTIFIER\d+) LPAREN\d+');
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'VALUE',                                                                    _NodePattern     := '(?:^| )((?#VALUE)\d+)');
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'CALL_EXPRESSION',                   _Input := 'VALUE', _NodeGroup := 'VALUE', _NodePattern     := '(?:^| )(VALUE\d+ LPAREN\d+(?: (?:VALUE\d+|COMMA\d+|(?#OPS)\d+))* RPAREN\d+)');
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'SUB_EXPRESSION',                    _Input := 'VALUE', _NodeGroup := 'VALUE', _NodePattern     := '(?:^| )(LPAREN\d+(?: (?:VALUE\d+|(?#OPS)\d+))+ RPAREN\d+)');
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'EXPRESSION',                        _Input := 'VALUE',                     _NodePattern     := '(?:^| )((?:VALUE\d+|CALL\d+|GROUP\d+|(?#OPS)\d+)(?: (?:VALUE\d+|CALL\d+|GROUP\d+|(?#OPS)\d+))*)');
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'CALL',                              _Input := 'VALUE', _Output := 'VALUE', _NodePattern     := '(?:^| )(VALUE\d+ LPAREN\d+(?: VALUE\d+(?: COMMA\d+ VALUE\d+)*)? RPAREN\d+)');
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'GROUP',                             _Input := 'VALUE', _Output := 'VALUE', _NodePattern     := '(?:^| )(LPAREN\d+ VALUE\d+ RPAREN\d+)');
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'UNARY_MINUS',                       _Input := 'VALUE', _Output := 'VALUE', _NodePattern     := '(?:^|(?:^| )(?!VALUE\d+ )[A-Z_]+\d+ )(MINUS\d+ VALUE\d+)');
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'MULTIPLY',                          _Input := 'VALUE', _Output := 'VALUE', _NodePattern     := '(?:^| )(VALUE\d+ ASTERISK\d+ VALUE\d+)');
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'DIVIDE',                            _Input := 'VALUE', _Output := 'VALUE', _NodePattern     := '(?:^| )(VALUE\d+ SLASH\d+ VALUE\d+)');
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'SUBTRACT',                          _Input := 'VALUE', _Output := 'VALUE', _NodePattern     := '(?:^| )(VALUE\d+ MINUS\d+ VALUE\d+)');
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'ADD',                               _Input := 'VALUE', _Output := 'VALUE', _NodePattern     := '(?:^| )(VALUE\d+ PLUS\d+ VALUE\d+)');
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'LESS_THAN',                         _Input := 'VALUE', _Output := 'VALUE', _NodePattern     := '(?:^| )(VALUE\d+ LT\d+ VALUE\d+)');
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'GREATER_THAN',                      _Input := 'VALUE', _Output := 'VALUE', _NodePattern     := '(?:^| )(VALUE\d+ GT\d+ VALUE\d+)');
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'EQUAL',                             _Input := 'VALUE', _Output := 'VALUE', _NodePattern     := '(?:^| )(VALUE\d+ EQ_EQ\d+ VALUE\d+)');
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'NOT_EQUAL',                         _Input := 'VALUE', _Output := 'VALUE', _NodePattern     := '(?:^| )(VALUE\d+ BANG_EQ\d+ VALUE\d+)');
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'FREE_STATEMENT');
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'LET_STATEMENT',                     _PostVisitFunction := 'NEW_VARIABLE_NODE',       _NodePattern     := '(?:^| )(LET\d+ SET_VARIABLE\d+ EQ\d+ EXPRESSION\d+ SEMICOLON\d+)');
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'EXPRESSION_STATEMENT',                                                               _NodePattern     := '(?:^| )(EXPRESSION\d+ SEMICOLON\d+)');
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'BLOCK_STATEMENT',                                                                    _NodePattern     := '(?:^| )(LBRACE\d+(?: STATEMENT\d+)* RBRACE\d+)');
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'BLOCK_EXPRESSION',                                                                   _NodePattern     := '(?:^| )(LBRACE\d+(?: STATEMENT\d+)* EXPRESSION\d+ RBRACE\d+)');
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'ALLOCA');
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'RET');
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'FUNCTION_LABEL');
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'FUNCTION_DECLARATION', _NodeGroup := 'VALUE', _Prologue := 'ALLOCA', _Epilogue := 'RET',                    _NodePattern     := '(?:^| )(FUNCTION\d+ STORE_ARGS\d+ (?:BLOCK_EXPRESSION\d+|STATEMENTS\d+))');
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'FUNCTION_ARGS',                                                                      _NodePattern     := '(?:^| )(?:IDENTIFIER\d+ )(LPAREN\d+(?: (?:IDENTIFIER\d+|EXPRESSION\d+)(?: COMMA\d+ (?:IDENTIFIER\d+|EXPRESSION\d+))*)? RPAREN\d+)');
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'FUNCTION_CALL',                                                                      _NodePattern     := '(?:^| )(IDENTIFIER\d+ FUNCTION_ARGS\d+)', _PreVisitFunction := 'GET_FUNCTION_NODE');
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'IF_STATEMENT',                                                                       _NodePattern     := '(?:^| )(IF\d+ EXPRESSION\d+ STATEMENT\d+ ELSE\d+ STATEMENT\d+)');
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'IF_EXPRESSION', _NodeGroup := 'VALUE',                                               _NodePattern     := '(?:^| )(IF\d+ EXPRESSION\d+ BLOCK_EXPRESSION\d+ ELSE\d+ BLOCK_EXPRESSION\d+)');
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'STATEMENT',                                                                          _NodePattern     := '(?:^| )(LET_STATEMENT\d+|ASSIGNMENT_STATEMENT\d+|EXPRESSION_STATEMENT\d+|BLOCK_STATEMENT\d+|LOOP_STATEMENT\d+|IF_STATEMENT\d+|BREAK_STATEMENT\d+|CONTINUE_STATEMENT\d+)');
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'STATEMENTS',                                                                         _NodePattern     := '(?:^| )(STATEMENT\d+(?: STATEMENT\d+)*)');
SELECT soft.New_Node_Type(_Language := 'monkey', _NodeType := 'PROGRAM',             _Prologue := 'ALLOCA', _Epilogue := 'RET',                     _NodePattern     := '(?:^| )(STATEMENTS\d+)');

CREATE SCHEMA "MAP_SET_GET_NODES";
SELECT soft.New_Bonsai_Schema(_Language := 'monkey', _BonsaiSchema := 'MAP_SET_GET_NODES');


CREATE OR REPLACE FUNCTION "MAP_SET_GET_NODES"."LET_STATEMENT"(_VisitType text) RETURNS void
SET search_path TO soft, public, pg_temp
LANGUAGE plpgsql
AS $$
DECLARE
_NodeTypeID integer;
_CurrentNodeID integer;
_Visited integer;
_VariableNodeID integer;
_OK boolean;
_NameValue name;
BEGIN
IF _VisitType <> 'POST_VISIT' THEN
    RETURN;
END IF;
SELECT NodeID INTO STRICT _CurrentNodeID FROM Programs;
SELECT NodeTypeID INTO STRICT _NodeTypeID FROM NodeTypes WHERE NodeType = 'VARIABLE';
SELECT
    ChildNode.Visited,
    ParentNode.NameValue,
    ParentNode.NodeID
INTO STRICT
    _Visited,
    _NameValue,
    _VariableNodeID
FROM Nodes AS ChildNode
INNER JOIN Edges ON Edges.ChildNodeID = ChildNode.NodeID
INNER JOIN Nodes AS ParentNode ON ParentNode.NodeID = Edges.ParentNodeID
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = ParentNode.NodeTypeID
WHERE ChildNode.NodeID = _CurrentNodeID
AND NodeTypes.NodeType = 'SET_VARIABLE';
SELECT Visited INTO STRICT _Visited FROM Nodes WHERE NodeID = _CurrentNodeID;
UPDATE Nodes SET NodeTypeID = _NodeTypeID WHERE NodeID = _VariableNodeID RETURNING TRUE INTO STRICT _OK;
RAISE NOTICE 'MAP_SET_GET_NODES LET_STATEMENT _CurrentNodeID % _NameValue % -> _VariableNodeID %', _CurrentNodeID, _NameValue, _VariableNodeID;
UPDATE Nodes SET Visited = _Visited WHERE NodeID = _VariableNodeID RETURNING TRUE INTO STRICT _OK;
RETURN;
END;
$$;

CREATE OR REPLACE FUNCTION "MAP_SET_GET_NODES"."GET_VARIABLE"(_VisitType text) RETURNS void
SET search_path TO soft, public, pg_temp
LANGUAGE plpgsql
AS $$
DECLARE
_CurrentNodeID integer;
_Visited integer;
_VariableNodeID integer;
_OK boolean;
_NameValue name;
_ChildNodeID integer;
BEGIN
IF _VisitType <> 'PRE_VISIT' THEN
    RETURN;
END IF;
SELECT NodeID INTO STRICT _CurrentNodeID FROM Programs;
RAISE NOTICE 'GET_VARIABLE _CurrentNodeID %', _CurrentNodeID;
SELECT Visited, NameValue INTO STRICT _Visited, _NameValue FROM Nodes WHERE NodeID = _CurrentNodeID AND ValueType = 'name'::regtype;
_VariableNodeID := Find_Variable_Node(_CurrentNodeID, 'LET_STATEMENT', _NameValue);
SELECT ChildNodeID INTO STRICT _ChildNodeID FROM Edges WHERE ParentNodeID = _CurrentNodeID;
UPDATE Programs SET NodeID = _ChildNodeID WHERE NodeID = _CurrentNodeID RETURNING TRUE INTO STRICT _OK;
UPDATE Edges SET ParentNodeID = _VariableNodeID WHERE ParentNodeID = _CurrentNodeID RETURNING TRUE INTO STRICT _OK;
DELETE FROM Nodes WHERE NodeID = _CurrentNodeID RETURNING TRUE INTO STRICT _OK;
RAISE NOTICE 'MAP_SET_GET_NODES GET_VARIABLE _CurrentNodeID % _NameValue % <- _VariableNodeID %', _CurrentNodeID, _NameValue, _VariableNodeID;
RETURN;
END;
$$;



CREATE OR REPLACE FUNCTION soft."FUNCTION_CALL"(name) RETURNS void
SET search_path TO soft, public, pg_temp
LANGUAGE plpgsql
AS $$
DECLARE
_Visited integer;
_OK boolean;
_CurrentNodeID integer;
_FunctionNameNodeID integer;
_FunctionDeclarationNodeID integer;
_RetNodeID integer;
_RetEdgeID integer;
_LastNodeID integer;
_AllocaNodeID integer;
_VariableNodeID integer;
BEGIN

SELECT NodeID INTO STRICT _CurrentNodeID FROM Programs;

SELECT EdgeID, ChildNodeID INTO _RetEdgeID, _RetNodeID FROM Edges WHERE ParentNodeID = _CurrentNodeID ORDER BY EdgeID OFFSET 1 LIMIT 1;
IF NOT FOUND THEN
    RAISE NOTICE 'Outgoing function call at %', _CurrentNodeID;
    SELECT Visited INTO STRICT _Visited FROM Nodes WHERE NodeID = _CurrentNodeID;
    SELECT ParentNodeID INTO STRICT _FunctionNameNodeID        FROM Edges WHERE ChildNodeID = _CurrentNodeID ORDER BY EdgeID LIMIT 1;
    SELECT ParentNodeID INTO STRICT _FunctionDeclarationNodeID FROM Edges WHERE ChildNodeID = _FunctionNameNodeID;
    SELECT ParentNodeID INTO STRICT _RetNodeID FROM Edges WHERE ChildNodeID = _FunctionDeclarationNodeID ORDER BY EdgeID DESC LIMIT 1;
    UPDATE Nodes SET Visited = Visited+1 WHERE NodeID = _FunctionDeclarationNodeID RETURNING TRUE INTO STRICT _OK;
    UPDATE Nodes SET Visited = _Visited-1 WHERE NodeID = _CurrentNodeID RETURNING TRUE INTO STRICT _OK;
    UPDATE Programs SET NodeID = _FunctionDeclarationNodeID RETURNING TRUE INTO STRICT _OK;
    INSERT INTO Edges (ParentNodeID, ChildNodeID) VALUES (_CurrentNodeID, _RetNodeID) RETURNING TRUE INTO STRICT _OK;
ELSE
    UPDATE Nodes SET Visited = _Visited+1 WHERE NodeID = _CurrentNodeID RETURNING TRUE INTO STRICT _OK;
    SELECT ChildNodeID INTO STRICT _FunctionDeclarationNodeID FROM Edges WHERE ParentNodeID = _RetNodeID;
    SELECT ParentNodeID INTO STRICT _LastNodeID FROM Edges WHERE ChildNodeID = _FunctionDeclarationNodeID ORDER BY EdgeID DESC OFFSET 1 LIMIT 1;
    RAISE NOTICE 'Returning function call at % copying value from %', _CurrentNodeID, _LastNodeID;
    PERFORM Copy_Node(_LastNodeID, _CurrentNodeID);
    DELETE FROM Edges WHERE EdgeID = _RetEdgeID RETURNING TRUE INTO STRICT _OK;
    SELECT ParentNodeID INTO STRICT _AllocaNodeID FROM Edges WHERE ChildNodeID = _FunctionDeclarationNodeID ORDER BY EdgeID LIMIT 1;
    FOR _VariableNodeID IN
    SELECT ParentNodeID FROM Edges WHERE ChildNodeID = _AllocaNodeID ORDER BY EdgeID
    LOOP
        PERFORM Pop_Node(_VariableNodeID);
    END LOOP;
END IF;

RETURN;
END;
$$;

CREATE OR REPLACE FUNCTION soft."RET"() RETURNS void
SET search_path TO soft, public, pg_temp
LANGUAGE plpgsql
AS $$
DECLARE
BEGIN
RETURN;
END;
$$;


CREATE OR REPLACE FUNCTION soft."BLOCK_EXPRESSION"(anyelement) RETURNS void
SET search_path TO soft, public, pg_temp
LANGUAGE plpgsql
AS $$
DECLARE
_CurrentNodeID integer;
_LastNodeID integer;
_OK boolean;
BEGIN

SELECT NodeID INTO STRICT _CurrentNodeID FROM Programs;

SELECT ParentNodeID INTO STRICT _LastNodeID FROM Edges WHERE ChildNodeID = _CurrentNodeID ORDER BY EdgeID DESC LIMIT 1;

PERFORM Copy_Node(_LastNodeID, _CurrentNodeID);

RETURN;
END;
$$;


CREATE OR REPLACE FUNCTION soft."STORE_ARGS"() RETURNS void
SET search_path TO soft, public, pg_temp
LANGUAGE plpgsql
AS $$
DECLARE
_CurrentNodeID integer;
_FunctionArgsNodeID integer;
_CopyFromNodeIDs integer[];
_CopyToNodeIDs integer[];
_OK boolean;
BEGIN

SELECT NodeID INTO STRICT _CurrentNodeID FROM Programs;

_FunctionArgsNodeID := Find_Node(_CurrentNodeID, '-> FUNCTION_DECLARATION <- RET <- FUNCTION_CALL <- FUNCTION_ARGS');

SELECT array_agg(ParentNodeID ORDER BY EdgeID) INTO STRICT _CopyFromNodeIDs FROM Edges WHERE ChildNodeID = _FunctionArgsNodeID;
SELECT array_agg(ParentNodeID ORDER BY EdgeID) INTO STRICT _CopyToNodeIDs   FROM Edges WHERE ChildNodeID = _CurrentNodeID;

IF (array_length(_CopyFromNodeIDs,1) = array_length(_CopyToNodeIDs,1)) IS NOT TRUE THEN
    RAISE EXCEPTION 'Number of function arguments differ between call args and the declared functions args: CurrentNodeID % FunctionArgsNodeID % CopyFromNodeIDs % CopyToNodeIDs %', _CurrentNodeID, _FunctionArgsNodeID, _CopyFromNodeIDs, _CopyToNodeIDs;
END IF;

RAISE NOTICE 'Store function args at % from node %', _CurrentNodeID, _FunctionArgsNodeID;

FOR _i IN 1..array_length(_CopyFromNodeIDs,1) LOOP
    RAISE NOTICE 'Copying node % to %', _CopyFromNodeIDs[_i], _CopyToNodeIDs[_i];
    PERFORM Copy_Node(_CopyFromNodeIDs[_i], _CopyToNodeIDs[_i]);
END LOOP;

RETURN;
END;
$$;


CREATE OR REPLACE FUNCTION soft."ALLOCA"(VARIADIC name[]) RETURNS void
SET search_path TO soft, public, pg_temp
LANGUAGE plpgsql
AS $$
DECLARE
_CurrentNodeID integer;
_VariableNodeID integer;
_NewNodeID integer;
_OK boolean;
BEGIN

SELECT NodeID INTO STRICT _CurrentNodeID FROM Programs;

RAISE NOTICE 'Allocating at %', _CurrentNodeID;

FOR _VariableNodeID IN
SELECT ParentNodeID FROM Edges WHERE ChildNodeID = _CurrentNodeID ORDER BY EdgeID
LOOP
    PERFORM Push_Node(_VariableNodeID);
END LOOP;

RETURN;
END;
$$;

CREATE OR REPLACE FUNCTION soft.Find_Variable_Node(_NodeID integer, _CreatorNodeType text, _NameValue name DEFAULT NULL) RETURNS integer
SET search_path TO soft, public, pg_temp
LANGUAGE plpgsql
AS $$
DECLARE
_VariableNodeID integer;
_OriginNodeID integer;
BEGIN
_OriginNodeID := _NodeID;
LOOP
    SELECT Variable.NodeID INTO _VariableNodeID
    FROM Nodes AS LetStatementChild
    INNER JOIN Edges AS Edge1 ON Edge1.ChildNodeID = LetStatementChild.NodeID
    INNER JOIN Nodes AS CreatorNode ON CreatorNode.NodeID = Edge1.ParentNodeID
    INNER JOIN Edges AS Edge2 ON Edge2.ChildNodeID = CreatorNode.NodeID
    INNER JOIN Nodes AS Variable ON Variable.NodeID = Edge2.ParentNodeID
    WHERE LetStatementChild.NodeID = _NodeID
    AND CreatorNode.NodeTypeID  = (SELECT NodeTypeID FROM NodeTypes WHERE NodeType = 'LET_STATEMENT')
    AND Variable.NodeTypeID     = (SELECT NodeTypeID FROM NodeTypes WHERE NodeType = 'VARIABLE')
    AND (Variable.NameValue     = _NameValue OR _NameValue IS NULL)
    ORDER BY Edge1.EdgeID DESC
    LIMIT 1;
    IF FOUND THEN
        RETURN _VariableNodeID;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM Edges WHERE ParentNodeID = _NodeID) THEN
        EXIT;
    END IF;
    SELECT ChildNodeID INTO STRICT _NodeID FROM Edges WHERE ParentNodeID = _NodeID ORDER BY EdgeID LIMIT 1;
END LOOP;

_NodeID := _OriginNodeID;
LOOP
    RAISE NOTICE 'NodeID %', _NodeID;
    SELECT Variable.NodeID INTO _VariableNodeID
    FROM Nodes AS LetStatementChild
    INNER JOIN Edges AS Edge1       ON Edge1.ChildNodeID  = LetStatementChild.NodeID
    INNER JOIN Nodes AS CreatorNode ON CreatorNode.NodeID = Edge1.ParentNodeID
    INNER JOIN Edges AS Edge2       ON Edge2.ChildNodeID  = CreatorNode.NodeID
    INNER JOIN Nodes AS Params      ON Params.NodeID      = Edge2.ParentNodeID
    INNER JOIN Edges AS Edge3       ON Edge3.ChildNodeID  = Params.NodeID
    INNER JOIN Nodes AS Variable    ON Variable.NodeID    = Edge3.ParentNodeID
    WHERE LetStatementChild.NodeID = _NodeID
    AND CreatorNode.NodeTypeID  = (SELECT NodeTypeID FROM NodeTypes WHERE NodeType = 'FUNCTION_DECLARATION')
    AND Params.NodeTypeID       = (SELECT NodeTypeID FROM NodeTypes WHERE NodeType = 'STORE_ARGS')
    AND Variable.NodeTypeID     = (SELECT NodeTypeID FROM NodeTypes WHERE NodeType = 'IDENTIFIER')
    AND (Variable.NameValue     = _NameValue OR _NameValue IS NULL)
    ORDER BY Edge1.EdgeID DESC
    LIMIT 1;
    IF FOUND THEN
        RETURN _VariableNodeID;
    END IF;
    SELECT ChildNodeID INTO _NodeID FROM Edges WHERE ParentNodeID = _NodeID ORDER BY EdgeID LIMIT 1;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Origin variable node for % not found from %', _NameValue, _NodeID;
    END IF;
END LOOP;

RETURN NULL; -- will never reach
END;
$$;

CREATE OR REPLACE FUNCTION soft."INIT_LOOP_STATEMENT"() RETURNS void
SET search_path TO soft, public, pg_temp
LANGUAGE plpgsql
AS $$
DECLARE
_NodeTypeID integer;
_CurrentNodeID integer;
_Visited integer;
_TrueNodeID integer;
_VariableNodeID integer;
_AssignmentNodeID integer;
_StatementsNodeID integer;
_OK boolean;
_NameValue name;
BEGIN

SELECT NodeID INTO STRICT _CurrentNodeID FROM Programs;

SELECT New_Node(NodeTypeID, 'true', 'boolean'::regtype) INTO STRICT _TrueNodeID FROM NodeTypes WHERE NodeType = 'BOOLEAN';
SELECT New_Node(NodeTypeID) INTO STRICT _VariableNodeID FROM NodeTypes WHERE NodeType = 'VARIABLE';
SELECT New_Node(NodeTypeID) INTO STRICT _AssignmentNodeID FROM NodeTypes WHERE NodeType = 'LET_STATEMENT';
SELECT New_Node(NodeTypeID) INTO STRICT _StatementsNodeID FROM NodeTypes WHERE NodeType = 'STATEMENTS';

UPDATE Edges SET ParentNodeID = _StatementsNodeID WHERE ParentNodeID = _CurrentNodeID RETURNING TRUE INTO STRICT _OK;

INSERT INTO Edges (ParentNodeID, ChildNodeID) VALUES (_VariableNodeID, _AssignmentNodeID) RETURNING TRUE INTO STRICT _OK;
INSERT INTO Edges (ParentNodeID, ChildNodeID) VALUES (_TrueNodeID, _AssignmentNodeID) RETURNING TRUE INTO STRICT _OK;

INSERT INTO Edges (ParentNodeID, ChildNodeID) VALUES (_AssignmentNodeID, _StatementsNodeID) RETURNING TRUE INTO STRICT _OK;
INSERT INTO Edges (ParentNodeID, ChildNodeID) VALUES (_CurrentNodeID, _StatementsNodeID) RETURNING TRUE INTO STRICT _OK;

INSERT INTO Edges (ParentNodeID, ChildNodeID) VALUES (_VariableNodeID, _CurrentNodeID) RETURNING TRUE INTO STRICT _OK;

UPDATE Nodes SET Visited = 1 WHERE NodeID IN (_TrueNodeID, _VariableNodeID, _AssignmentNodeID, _StatementsNodeID);

RAISE NOTICE 'INIT_LOOP_STATEMENT _CurrentNodeID %', _CurrentNodeID;

RETURN;
END;
$$;

CREATE OR REPLACE FUNCTION soft."INIT_BREAK_STATEMENT"() RETURNS void
SET search_path TO soft, public, pg_temp
LANGUAGE plpgsql
AS $$
DECLARE
_NodeTypeID integer;
_CurrentNodeID integer;
_Visited integer;
_VariableNodeID integer;
_LoopNodeID integer;
_OK boolean;
_NameValue name;
BEGIN

SELECT NodeID INTO STRICT _CurrentNodeID FROM Programs;

_VariableNodeID := Find_Variable_Node(_CurrentNodeID, 'LOOP_STATEMENT');

RAISE NOTICE 'INIT_BREAK_STATEMENT _CurrentNodeID % -> _VariableNodeID %', _CurrentNodeID, _VariableNodeID;

DELETE FROM Edges WHERE ChildNodeID = _CurrentNodeID RETURNING TRUE INTO STRICT _OK;
INSERT INTO Edges (ParentNodeID, ChildNodeID) VALUES (_VariableNodeID, _CurrentNodeID) RETURNING TRUE INTO STRICT _OK;

RETURN;
END;
$$;

CREATE OR REPLACE FUNCTION soft."INIT_CONTINUE_STATEMENT"() RETURNS void
SET search_path TO soft, public, pg_temp
LANGUAGE plpgsql
AS $$
DECLARE
_NodeTypeID integer;
_CurrentNodeID integer;
_Visited integer;
_VariableNodeID integer;
_LoopNodeID integer;
_OK boolean;
_NameValue name;
BEGIN

SELECT NodeID INTO STRICT _CurrentNodeID FROM Programs;

_VariableNodeID := Find_Variable_Node(_CurrentNodeID, 'LOOP_STATEMENT');

RAISE NOTICE 'INIT_CONTINUE_STATEMENT _CurrentNodeID % -> _VariableNodeID %', _CurrentNodeID, _VariableNodeID;

DELETE FROM Edges WHERE ChildNodeID = _CurrentNodeID RETURNING TRUE INTO STRICT _OK;
INSERT INTO Edges (ParentNodeID, ChildNodeID) VALUES (_VariableNodeID, _CurrentNodeID) RETURNING TRUE INTO STRICT _OK;

RETURN;
END;
$$;

CREATE OR REPLACE FUNCTION soft."GET_FUNCTION_NODE"() RETURNS void
SET search_path TO soft, public, pg_temp
LANGUAGE plpgsql
AS $$
DECLARE
_CurrentNodeID integer;
_Visited integer;
_VariableNodeID integer;
_OK boolean;
_NameValue name;
_ChildNodeID integer;
BEGIN

SELECT NodeID INTO STRICT _CurrentNodeID FROM Programs;

SELECT ParentNodeID INTO STRICT _CurrentNodeID FROM Edges WHERE ChildNodeID = _CurrentNodeID ORDER BY EdgeID LIMIT 1;

RAISE NOTICE 'GET_FUNCTION_NODE _CurrentNodeID %', _CurrentNodeID;

SELECT Visited, NameValue INTO STRICT _Visited, _NameValue FROM Nodes WHERE NodeID = _CurrentNodeID AND ValueType = 'name'::regtype;

_VariableNodeID := Find_Variable_Node(_CurrentNodeID, 'LET_STATEMENT', _NameValue);

RAISE NOTICE 'VariableNodeID %', _VariableNodeID;

SELECT ChildNodeID INTO STRICT _ChildNodeID FROM Edges WHERE ParentNodeID = _CurrentNodeID;

UPDATE Edges SET ParentNodeID = _VariableNodeID WHERE ParentNodeID = _CurrentNodeID RETURNING TRUE INTO STRICT _OK;
DELETE FROM Nodes WHERE NodeID = _CurrentNodeID RETURNING TRUE INTO STRICT _OK;

RAISE NOTICE 'GET_FUNCTION_NODE _CurrentNodeID % _NameValue % <- _VariableNodeID %', _CurrentNodeID, _NameValue, _VariableNodeID;

RETURN;
END;
$$;

CREATE OR REPLACE FUNCTION soft."SET_VARIABLE_NODE"() RETURNS void
SET search_path TO soft, public, pg_temp
LANGUAGE plpgsql
AS $$
DECLARE
_NodeTypeID integer;
_CurrentNodeID integer;
_Visited integer;
_VariableNodeID integer;
_OK boolean;
_NameValue name;
_ParentNodeID integer;
BEGIN
SELECT NodeID INTO STRICT _CurrentNodeID FROM Programs;
SELECT NodeTypeID INTO STRICT _NodeTypeID FROM NodeTypes WHERE NodeType = 'VARIABLE';

SELECT
    ChildNode.Visited,
    ParentNode.NameValue,
    ParentNode.NodeID
INTO STRICT
    _Visited,
    _NameValue,
    _ParentNodeID
FROM Nodes AS ChildNode
INNER JOIN Edges ON Edges.ChildNodeID = ChildNode.NodeID
INNER JOIN Nodes AS ParentNode ON ParentNode.NodeID = Edges.ParentNodeID
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = ParentNode.NodeTypeID
WHERE ChildNode.NodeID = _CurrentNodeID
AND NodeTypes.NodeType = 'SET_VARIABLE';

_VariableNodeID := Find_Variable_Node(_CurrentNodeID, 'LET_STATEMENT', _NameValue);

RAISE NOTICE 'SET_VARIABLE_NODE _CurrentNodeID % _NameValue % -> _VariableNodeID %', _CurrentNodeID, _NameValue, _VariableNodeID;

UPDATE Edges SET ParentNodeID = _VariableNodeID WHERE ParentNodeID = _ParentNodeID RETURNING TRUE INTO STRICT _OK;
DELETE FROM Nodes WHERE NodeID = _ParentNodeID RETURNING TRUE INTO STRICT _OK;

RETURN;
END;
$$;

CREATE OR REPLACE FUNCTION soft."LOOP_STATEMENT"(boolean) RETURNS void
SET search_path TO soft, public, pg_temp
LANGUAGE plpgsql
AS $$
DECLARE
_CurrentNodeID integer;
_ParentNodeID integer;
_VariableNodeID integer;
_OK boolean;
BEGIN

SELECT NodeID INTO STRICT _CurrentNodeID FROM Programs;

IF $1 THEN
    RAISE NOTICE 'LOOP *** %', _CurrentNodeID;
    UPDATE Nodes SET Visited = Visited + 1 WHERE NodeID = _CurrentNodeID RETURNING TRUE INTO STRICT _OK;
    SELECT ParentNodeID INTO STRICT _ParentNodeID FROM Edges WHERE ChildNodeID = _CurrentNodeID ORDER BY EdgeID LIMIT 1;
    UPDATE Programs SET NodeID = _ParentNodeID RETURNING TRUE INTO STRICT _OK;
ELSE
    SELECT ParentNodeID INTO STRICT _VariableNodeID FROM Edges WHERE ChildNodeID = _CurrentNodeID ORDER BY EdgeID DESC LIMIT 1;
    UPDATE Nodes SET BooleanValue = TRUE WHERE NodeID = _VariableNodeID RETURNING TRUE INTO STRICT _OK;
    RAISE NOTICE 'END LOOP *** %', _CurrentNodeID;
END IF;

RETURN;
END;
$$;

CREATE OR REPLACE FUNCTION soft."BREAK_STATEMENT"(boolean) RETURNS void
SET search_path TO soft, public, pg_temp
LANGUAGE plpgsql
AS $$
DECLARE
_CurrentNodeID integer;
_ParentNodeID integer;
_FreeNodeID integer;
_OK boolean;
BEGIN

SELECT NodeID INTO STRICT _CurrentNodeID FROM Programs;
SELECT ParentNodeID INTO STRICT _ParentNodeID FROM Edges WHERE ChildNodeID = _CurrentNodeID;
SELECT ChildNodeID INTO STRICT _FreeNodeID FROM Edges WHERE ParentNodeID = _ParentNodeID ORDER BY EdgeID DESC LIMIT 1;

RAISE NOTICE 'BREAK LOOP *** %', _CurrentNodeID;
UPDATE Programs SET NodeID = _FreeNodeID RETURNING TRUE INTO STRICT _OK;

RETURN;
END;
$$;

CREATE OR REPLACE FUNCTION soft."CONTINUE_STATEMENT"(boolean) RETURNS void
SET search_path TO soft, public, pg_temp
LANGUAGE plpgsql
AS $$
DECLARE
_CurrentNodeID integer;
_ParentNodeID integer;
_LoopNodeID integer;
_OK boolean;
BEGIN

SELECT NodeID INTO STRICT _CurrentNodeID FROM Programs;
SELECT ParentNodeID INTO STRICT _ParentNodeID FROM Edges WHERE ChildNodeID = _CurrentNodeID;

SELECT Edges.ChildNodeID INTO STRICT _LoopNodeID FROM Edges
INNER JOIN Nodes ON Nodes.NodeID = Edges.ChildNodeID
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
WHERE Edges.ParentNodeID = _ParentNodeID
AND NodeTypes.NodeType = 'LOOP_STATEMENT';

RAISE NOTICE 'CONTINUE LOOP *** % -> %', _CurrentNodeID, _LoopNodeID;
UPDATE Programs SET NodeID = _LoopNodeID RETURNING TRUE INTO STRICT _OK;

RETURN;
END;
$$;


CREATE OR REPLACE FUNCTION soft."IF_STATEMENT"(boolean) RETURNS void
SET search_path TO soft, public, pg_temp
LANGUAGE plpgsql
AS $$
DECLARE
_CurrentNodeID integer;
_ConditionNodeID integer;
_TrueNodeID integer;
_FalseNodeID integer;
_BranchNodeID integer;
_IfVisited integer;
_TrueVisited integer;
_ElseVisited integer;
_OK boolean;
BEGIN

SELECT NodeID INTO STRICT _CurrentNodeID FROM Programs;

SELECT ParentNodeID INTO STRICT _ConditionNodeID FROM Edges WHERE ChildNodeID  = _CurrentNodeID ORDER BY EdgeID OFFSET 0 LIMIT 1;
SELECT ParentNodeID INTO STRICT _TrueNodeID      FROM Edges WHERE ChildNodeID  = _CurrentNodeID ORDER BY EdgeID OFFSET 1 LIMIT 1;
SELECT ParentNodeID INTO        _FalseNodeID     FROM Edges WHERE ChildNodeID  = _CurrentNodeID ORDER BY EdgeID OFFSET 2 LIMIT 1;

SELECT Visited INTO STRICT _IfVisited    FROM Nodes WHERE NodeID = _CurrentNodeID;
SELECT Visited INTO STRICT _TrueVisited  FROM Nodes WHERE NodeID = _TrueNodeID;
SELECT Visited INTO        _ElseVisited  FROM Nodes WHERE NodeID = _FalseNodeID;

IF _TrueVisited IS NOT NULL THEN
    RAISE NOTICE '*** RETURN FROM TRUE BRANCH';
    UPDATE Nodes SET Visited = NULL WHERE NodeID = _TrueNodeID RETURNING TRUE INTO STRICT _OK;
    UPDATE Nodes SET Visited = Visited - 1 WHERE NodeID = _ConditionNodeID RETURNING TRUE INTO STRICT _OK;
ELSIF _ElseVisited IS NOT NULL THEN
    RAISE NOTICE '*** RETURN FROM FALSE BRANCH';
    UPDATE Nodes SET Visited = NULL WHERE NodeID = _FalseNodeID RETURNING TRUE INTO STRICT _OK;
    UPDATE Nodes SET Visited = Visited - 1 WHERE NodeID = _ConditionNodeID RETURNING TRUE INTO STRICT _OK;
ELSE
    IF $1 THEN
        RAISE NOTICE '**** IF_STATEMENT IS TRUE';
        _BranchNodeID := _TrueNodeID;
    ELSE
        RAISE NOTICE '**** IF_STATEMENT IS FALSE';
        _BranchNodeID := _FalseNodeID;
    END IF;
    UPDATE Programs SET NodeID = _BranchNodeID WHERE NodeID = _CurrentNodeID RETURNING TRUE INTO STRICT _OK;
    UPDATE Nodes SET Visited = _IfVisited WHERE NodeID = _BranchNodeID RETURNING TRUE INTO STRICT _OK;
END IF;

RETURN;
END;
$$;

CREATE OR REPLACE FUNCTION soft."ASSIGNMENT_STATEMENT"(anyelement) RETURNS void
SET search_path TO soft, public, pg_temp
LANGUAGE plpgsql
AS $$
DECLARE
_CurrentNodeID integer;
_ValueNodeID integer;
_OK boolean;
BEGIN
SELECT NodeID INTO STRICT _CurrentNodeID FROM Programs;
SELECT ParentNodeID INTO STRICT _ValueNodeID FROM Edges WHERE ChildNodeID = _CurrentNodeID ORDER BY EdgeID LIMIT 1;
PERFORM Set_Node_Value(_ValueNodeID, $1);
RETURN;
END;
$$;

CREATE OR REPLACE FUNCTION soft."LET_STATEMENT"(anyelement) RETURNS void
SET search_path TO soft, public, pg_temp
LANGUAGE plpgsql
AS $$
DECLARE
_CurrentNodeID integer;
_ValueNodeID integer;
_OK boolean;
BEGIN
SELECT NodeID INTO STRICT _CurrentNodeID FROM Programs;
SELECT ParentNodeID INTO STRICT _ValueNodeID FROM Edges WHERE ChildNodeID = _CurrentNodeID ORDER BY EdgeID LIMIT 1;
UPDATE Nodes SET
    ValueType    = NULL,
    NameValue    = NULL,
    BooleanValue = NULL,
    NumericValue = NULL,
    IntegerValue = NULL,
    TextValue    = NULL
WHERE NodeID = _ValueNodeID
RETURNING TRUE INTO STRICT _OK;
PERFORM soft."ASSIGNMENT_STATEMENT"($1);
END;
$$;

CREATE OR REPLACE FUNCTION soft."FREE_STATEMENT"(anyelement) RETURNS void
SET search_path TO soft, public, pg_temp
LANGUAGE plpgsql
AS $$
DECLARE
_NodeTypeID integer;
_CurrentNodeID integer;
_ValueNodeID integer;
_OldOldValueNodeID integer;
_NewOldValueNodeID integer;
_OK boolean;
BEGIN

SELECT NodeTypeID INTO STRICT _NodeTypeID FROM NodeTypes WHERE ValueType = pg_typeof($1);

SELECT NodeID INTO STRICT _CurrentNodeID FROM Programs;

SELECT ParentNodeID INTO STRICT _ValueNodeID FROM Edges WHERE ChildNodeID = _CurrentNodeID ORDER BY EdgeID DESC LIMIT 1;

SELECT ParentNodeID INTO STRICT _NewOldValueNodeID FROM Edges WHERE ChildNodeID = _ValueNodeID;

SELECT ParentNodeID INTO STRICT _OldOldValueNodeID FROM Edges WHERE ChildNodeID = _NewOldValueNodeID;

RAISE NOTICE 'FREE UPDATE _ValueNodeID % by setting it to values for _NewOldValueNodeID %', _ValueNodeID, _NewOldValueNodeID;

UPDATE Nodes AS CurValueNode SET
    NodeTypeID   = OldValueNode.NodeTypeID,
    ValueType    = OldValueNode.ValueType,
    NameValue    = OldValueNode.NameValue,
    BooleanValue = OldValueNode.BooleanValue,
    NumericValue = OldValueNode.NumericValue,
    IntegerValue = OldValueNode.IntegerValue,
    TextValue    = OldValueNode.TextValue
FROM Nodes AS OldValueNode
WHERE OldValueNode.NodeID = _NewOldValueNodeID
AND CurValueNode.NodeID = _ValueNodeID
RETURNING TRUE INTO STRICT _OK;

-- SOURCE_CODE(OldOldValueNodeID) -1> VARIABLE(NewOldValueNodeID) -2-> VARIABLE(ValueNodeID) -3> LET_STATEMENT(CurrentNodeID)
-- SOURCE_CODE(OldOldValueNodeID) -1> VARIABLE(ValueNodeID) -3> LET_STATEMENT(CurrentNodeID)

DELETE FROM Edges WHERE ParentNodeID = _NewOldValueNodeID AND ChildNodeID = _ValueNodeID RETURNING TRUE INTO STRICT _OK;
UPDATE Edges SET ChildNodeID = _ValueNodeID WHERE ParentNodeID = _OldOldValueNodeID AND ChildNodeID = _NewOldValueNodeID RETURNING TRUE INTO STRICT _OK;

DELETE FROM Nodes WHERE NodeID = _NewOldValueNodeID RETURNING TRUE INTO STRICT _OK;

RETURN;
END;
$$;



CREATE OR REPLACE FUNCTION soft."TERNARY"                  (boolean, anyelement, anyelement)    RETURNS anyelement LANGUAGE sql AS $$ SELECT CASE WHEN $1 THEN $2 ELSE $3 END $$;
CREATE OR REPLACE FUNCTION soft."LOGICAL_OR"               (boolean, boolean)                   RETURNS boolean    LANGUAGE sql AS $$ SELECT $1 OR $2                         $$;
CREATE OR REPLACE FUNCTION soft."LOGICAL_XOR"              (boolean, boolean)                   RETURNS boolean    LANGUAGE sql AS $$ SELECT NOT($1 AND $2)                   $$;
CREATE OR REPLACE FUNCTION soft."LOGICAL_AND"              (boolean, boolean)                   RETURNS boolean    LANGUAGE sql AS $$ SELECT $1 AND $2                        $$;
CREATE OR REPLACE FUNCTION soft."LOGICAL_NOT"              (boolean)                            RETURNS boolean    LANGUAGE sql AS $$ SELECT NOT $1                           $$;
CREATE OR REPLACE FUNCTION soft."BITWISE_OR"               (anyelement, anyelement)             RETURNS anyelement LANGUAGE sql AS $$ SELECT $1 | $2                          $$;
CREATE OR REPLACE FUNCTION soft."BITWISE_XOR"              (anyelement, anyelement)             RETURNS anyelement LANGUAGE sql AS $$ SELECT $1 # $2                          $$;
CREATE OR REPLACE FUNCTION soft."BITWISE_AND"              (anyelement, anyelement)             RETURNS anyelement LANGUAGE sql AS $$ SELECT $1 & $2                          $$;
CREATE OR REPLACE FUNCTION soft."EQUAL"                    (anyelement, anyelement)             RETURNS boolean    LANGUAGE sql AS $$ SELECT $1 = $2                          $$;
CREATE OR REPLACE FUNCTION soft."NOT_EQUAL"                (anyelement, anyelement)             RETURNS boolean    LANGUAGE sql AS $$ SELECT $1 <> $2                         $$;
CREATE OR REPLACE FUNCTION soft."LESS_THAN"                (anyelement, anyelement)             RETURNS boolean    LANGUAGE sql AS $$ SELECT $1 < $2                          $$;
CREATE OR REPLACE FUNCTION soft."GREATER_THAN"             (anyelement, anyelement)             RETURNS boolean    LANGUAGE sql AS $$ SELECT $1 > $2                          $$;
CREATE OR REPLACE FUNCTION soft."LESS_THAN_OR_EQUAL_TO"    (anyelement, anyelement)             RETURNS boolean    LANGUAGE sql AS $$ SELECT $1 <= $2                         $$;
CREATE OR REPLACE FUNCTION soft."GREATER_THAN_OR_EQUAL_TO" (anyelement, anyelement)             RETURNS boolean    LANGUAGE sql AS $$ SELECT $1 >= $2                         $$;
CREATE OR REPLACE FUNCTION soft."BITWISE_SHIFT_LEFT"       (anyelement, anyelement)             RETURNS anyelement LANGUAGE sql AS $$ SELECT $1 << $2::integer                $$;
CREATE OR REPLACE FUNCTION soft."BITWISE_SHIFT_RIGHT"      (anyelement, anyelement)             RETURNS anyelement LANGUAGE sql AS $$ SELECT $1 >> $2::integer                $$;
CREATE OR REPLACE FUNCTION soft."BETWEEN"                  (anyelement, anyelement, anyelement) RETURNS boolean    LANGUAGE sql AS $$ SELECT $1 BETWEEN $2 AND $3             $$;
CREATE OR REPLACE FUNCTION soft."SQUARE_ROOT"              (anyelement)                         RETURNS anyelement LANGUAGE sql AS $$ SELECT |/ $1                            $$;
CREATE OR REPLACE FUNCTION soft."CUBE_ROOT"                (anyelement)                         RETURNS anyelement LANGUAGE sql AS $$ SELECT ||/ $1                           $$;
CREATE OR REPLACE FUNCTION soft."FACTOR"                   (anyelement)                         RETURNS anyelement LANGUAGE sql AS $$ SELECT $1 !                             $$;
CREATE OR REPLACE FUNCTION soft."ABS"                      (anyelement)                         RETURNS anyelement LANGUAGE sql AS $$ SELECT @ $1                             $$;
CREATE OR REPLACE FUNCTION soft."ADD"                      (anyelement, anyelement)             RETURNS anyelement LANGUAGE sql AS $$ SELECT $1 + $2                          $$;
CREATE OR REPLACE FUNCTION soft."SUBTRACT"                 (anyelement, anyelement)             RETURNS anyelement LANGUAGE sql AS $$ SELECT $1 - $2                          $$;
CREATE OR REPLACE FUNCTION soft."MULTIPLY"                 (anyelement, anyelement)             RETURNS anyelement LANGUAGE sql AS $$ SELECT $1 * $2                          $$;
CREATE OR REPLACE FUNCTION soft."DIVIDE"                   (anyelement, anyelement)             RETURNS anyelement LANGUAGE sql AS $$ SELECT $1 / $2                          $$;
CREATE OR REPLACE FUNCTION soft."MODULO"                   (anyelement, anyelement)             RETURNS anyelement LANGUAGE sql AS $$ SELECT $1 % $2                          $$;
CREATE OR REPLACE FUNCTION soft."EXPONENT"                 (anyelement, anyelement)             RETURNS anyelement LANGUAGE sql AS $$ SELECT ($1 ^ $2)::integer                $$;
CREATE OR REPLACE FUNCTION soft."UNARY_MINUS"              (anyelement)                         RETURNS anyelement LANGUAGE sql AS $$ SELECT - $1                             $$;
CREATE OR REPLACE FUNCTION soft."UNARY_PLUS"               (anyelement)                         RETURNS anyelement LANGUAGE sql AS $$ SELECT + $1                             $$;
CREATE OR REPLACE FUNCTION soft."BITWISE_NOT"              (anyelement)                         RETURNS anyelement LANGUAGE sql AS $$ SELECT ~$1                              $$;
CREATE OR REPLACE FUNCTION soft."ARRAY_INDEX"              (anyarray, integer)                  RETURNS anyelement LANGUAGE sql AS $$ SELECT $1[$2]                           $$;
CREATE OR REPLACE FUNCTION soft."INCREMENT"                (anyelement)                         RETURNS anyelement LANGUAGE sql AS $$ SELECT $1 + 1                           $$;
CREATE OR REPLACE FUNCTION soft."DECREMENT"                (anyelement)                         RETURNS anyelement LANGUAGE sql AS $$ SELECT $1 - 1                           $$;

SELECT soft.New_Program(
    _Language := 'monkey',
    _Program := 'test',
    _SourceCodeNodeID := soft.New_Node(
        _NodeTypeID := soft.New_Node_Type(_Language := 'monkey', _NodeType := 'SOURCE_CODE'),
        _Literal    :=
$$
let x = 2;
let y = 3;
let z = 4 * (x + y);
$$,
        _ValueType := 'text'::regtype
    )
);

/*
let add = fn(a, b) {
    let x = a + b;
    x
};
let aa = 3;
let bb = 4;
let z = add(2,add(aa,bb));
*/
